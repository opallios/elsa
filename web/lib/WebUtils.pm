package WebUtils;
use Moose::Role;

sub extract_method {
	my $self = shift;
	my $uri = shift;
	$self->controller->log->debug('uri: ' . $uri);
	
	if ($uri =~ /\/([^\/\?]+)\??([^\/]*)$/){
		return $1;
	}
	return;
}

sub get_headers {
	my $self = shift;
	my $cb = pop(@_);
	my $no_form_params = shift;
	$no_form_params ||= 0;
#	my $dir = $self->controller->conf->get('email/base_url');
#	$dir =~ s/^https?\:\/\/[^\/]+\//\//; # strip off the URL to make $dir the URI
#	$dir = '';
	my $dir = $self->path_to_inc;
	my $HTML = <<'EOHTML'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
EOHTML
;

#	my $yui_css = YUI::css_link();
#	my $yui_js = YUI::js_link();
	my $yui = new YUI(%{ $self->controller->conf->get('yui') });
	$HTML .= $yui->css($dir);
	$HTML .= $yui->js($dir);

	my $template = <<'EOHTML'
<style type="text/css">
/*margin and padding on body element
  can introduce errors in determining
  element position and are not recommended;
  we turn them off as a foundation for YUI
  CSS treatments. */
body {
	margin:0;
	padding:0;
}
</style>
<link rel="stylesheet" type="text/css" href=%3$s/inc/custom.css />
<script type="text/javascript" src="%3$s/inc/Chart.min.js" ></script>
<script type="text/javascript" src="%3$s/inc/Chart.HorizontalBar.js" ></script>
<script type="text/javascript" src="%3$s/inc/chart.js" ></script>
<script type="text/javascript" src="%3$s/inc/utilities.js" ></script>
<script type="text/javascript" src="%3$s/inc/elsa.js" ></script>
<script type="text/javascript" src="%3$s/inc/main.js" ></script>
EOHTML
;

	if ($self->controller->conf->get('custom_javascript_includes')){
		foreach my $include (@{ $self->controller->conf->get('custom_javascript_includes') }){
			$template .= '<script type="text/javascript" src="' . $include . '" ></script>';
		}
	}

	$template .= '<script type="text/Javascript">';	

	if ($self->controller->conf->get('javascript_debug_mode')){
		$template .= 'YAHOO.ELSA.viewMode = \'' . $self->controller->conf->get('javascript_debug_mode') . '\';' . "\n";
	}
	$HTML .= sprintf($template, undef, undef, $dir);
	
	# Set the javascript var for admin here if necessary
	if ($self->session->get('user_info') and $self->session->get('user_info')->{is_admin}){
		$HTML .= 'YAHOO.ELSA.IsAdmin = true;' . "\n";
		
		# Set the URL for getPcap if applicable
		if ($self->controller->conf->get('pcap_url')){
			$HTML .= 'YAHOO.ELSA.pcapUrl = "' . $self->controller->conf->get('pcap_url') . '"' . "\n";
		}
		
		# Set the URL for getStream if applicable
		if ($self->controller->conf->get('streamdb_url')){
			$HTML .= 'YAHOO.ELSA.streamdbUrl = "' . $self->controller->conf->get('streamdb_url') . '"' . "\n";
		}
		
		# Set the URL for Block if applicable
		if ($self->controller->conf->get('block_url')){
			$HTML .= 'YAHOO.ELSA.blockUrl = "' . $self->controller->conf->get('block_url') . '"' . "\n";
		}
	}
	
	# Check to see if we want to use the same tab for each query by default
	if ($self->controller->conf->get('same_tab_for_queries_default')){
		$HTML .= 'YAHOO.ELSA.sameTabForQueries = 1;' . "\n";
	}
	
	# Check to see if we want grid results by default
	my $grid_by_user_pref;
	if (exists $self->session->get('user_info')->{preferences} and exists $self->session->get('user_info')->{preferences}->{tree}
		and exists $self->session->get('user_info')->{preferences}->{tree}->{default_settings}
		and defined $self->session->get('user_info')->{preferences}->{tree}->{default_settings}->{grid_display}){
		$grid_by_user_pref = $self->session->get('user_info')->{preferences}->{tree}->{default_settings}->{grid_display};
	}
	if (defined $grid_by_user_pref){
		$HTML .= 'YAHOO.ELSA.gridDisplay = ' . ($grid_by_user_pref ? 1 : 0). ';' . "\n";
	}
	elsif ($self->controller->conf->get('grid_view_default')){
		$HTML .= 'YAHOO.ELSA.gridDisplay = 1;' . "\n";
	}
	else {
		$HTML .= 'YAHOO.ELSA.gridDisplay = 0;' . "\n";
	}	
	
	# Set form params
	my $user = $self->controller->get_user($self->session->get('user_info')->{username});
	if ($no_form_params){
		$HTML .= '</script>' . "\n" . sprintf('<title>%s</title>', $self->title);
		$cb->($HTML);
	}
	else {
		$self->controller->get_form_params($user, sub {
			my $form_params = shift;
			if($form_params){
				$HTML .= 'var formParams = YAHOO.ELSA.formParams = ' . $self->controller->json->encode($form_params) . ';';
			}
			else {
				$self->controller->log->error('Unable to get form params: ' . Dumper($form_params));
				$HTML .= q/alert('Error contacting log server(s)');/;
			}
			
			$HTML .= <<'EOHTML'
YAHOO.util.Event.throwErrors = true; 
	/*
		Global object that should allow for the initial creation of the select dropdown
		If necessary, this might be devoured by 'classes' object
	*/
	
	classSelect = {
		values: {
			'0': 'New Class',
			'1': 'Test Class'
		},
		id: 'class',
		selected: ' ',
		onchange: 'loadClass(this.value);drawLabels();'
	};
	
	labelSearch = [];
	multipleInheritance = {};
	
</script>
EOHTML
;
	
			$HTML .= sprintf('<title>%s</title>', $self->title);
			$cb->($HTML);
		});
	}
}


sub get_index_body {
	my $self = shift;
	my $cb = shift;
	my $HTML = <<'EOHTML'
<script>YAHOO.util.Event.addListener(window, "load", YAHOO.ELSA.main);</script>
</head>
<body class=" yui-skin-sam">
    <div class="header" title="Opallios Distribution of ELSA">
        <img src="/inc/ode-logo.png" width="66" height="24">
    </div>
    <div class="content-wrapper">
<div id="menu_bar"></div>
<div id="panel_root"></div>
<!--<h1>Enterprise Log Search and Archive</h1>-->
<div id="query_form"></div>
<div id="logs">
	<div id="tabView">
	<ul class="yui-nav">
    </ul>
	    <div class="yui-content"></div>
    </div>
</div>
</div>
<div class="footer">
<span class="left-side">
<a target="_blank" href="http://www.opallios.org">Documentation</a> |
<a target="_blank" href="https://groups.google.com/forum/#!forum/enterprise-log-search-and-archive">Support</a>
</span>
<span class="right-side">
<a target="_blank" href="http://www.opallios.com/">Opallios Inc.</a> ODE 0.3
</span>
</div>
</body>
</html>
EOHTML
;

	$cb->($HTML);
}

1;
