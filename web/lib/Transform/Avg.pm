package Transform::Avg;
use Moose;
use Data::Dumper;
use CHI;
use AnyEvent::HTTP;
use Socket;
use JSON;
extends 'Transform';
our $Name = 'Avg';
# Whois transform plugin
has 'name' => (is => 'rw', isa => 'Str', required => 1, default => $Name);

sub BUILDARGS {
	my $class = shift;
##my $params = $class->SUPER::BUILDARGS(@_);
	my %params = @_;
	$params{groupby} = $params{args}->[0];
#	$params{log}->trace('Anup-1 records: ' . Dumper($params{results}));
	return \%params;
}

sub BUILDARGS {
	my $class = shift;
##my $params = $class->SUPER::BUILDARGS(@_);
	my %params = @_;
	$params{groupby} = $params{args}->[0];

	return \%params;
}

sub BUILD {
	my $self = shift;
	my $sums = {};
    my @mini ;
	my $i = 0;
	$mini[$i] = 0;

	foreach my $record ($self->results->all_results){
		$record->{transforms} ||= {};
		$record->{transforms}->{$Name} = {};
		foreach my $transform (keys %{ $record->{transforms} }){
#$self->log->trace('Anup-transform: ' . Dumper($transform));
			next unless ref($record->{transforms}->{$transform}) eq 'HASH';
			foreach my $transform_field (keys %{ $record->{transforms}->{$transform} }){
#$self->log->trace('Anup-transform-field: ' . Dumper($transform_field));

				if (ref($record->{transforms}->{$transform}->{$transform_field}) eq 'HASH'){
					if (exists $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby }){
						if (ref($record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby }) eq 'ARRAY'){
							foreach my $value (@{ $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby } }){
								if ($value =~ /^\d+$/){
								    $mini[$i]= $value;
									$sums->{ $value } += $value;
									$i++;
								}
								elsif ($record->{count}){
								    $mini[$i]= $value;
									$sums->{$value} += $record->{count};
									$i++;
								}
								else {
								    $mini[$i]= $value;
									$sums->{ $value }++;
									$i++;
								}
							}
						}
						else {
							if ($record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby } =~ /^\d+$/)
							{
							    $mini[$i]= $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby };
							    $sums->{ $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby } } += 
								$record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby };
								$i++;
							}
							elsif ($record->{count}){
							    $mini[$i]= $record->{count} ;
								$sums->{ $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby } } += $record->{count};
								$i++;
							}
							else {
							    $mini[$i]= $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby };
								$sums->{ $record->{transforms}->{$transform}->{$transform_field}->{ $self->groupby } }++;
								$i++;
							}
						}
					}
				}
				elsif (ref($record->{transforms}->{$transform}->{$transform_field}) eq 'ARRAY' 
					and $transform_field eq $self->groupby){
					foreach my $value (@{ $record->{transforms}->{$transform}->{$transform_field} }){
						if ($value =~ /^\d+$/){
						    $mini[$i]= $value;
							$sums->{ $value } += $value;
							$i++;
												}
						elsif ($record->{count}){
						    $mini[$i]= $value;
							$sums->{$value} += $record->{count};
							$i++;
						}
						else {
						    $mini[$i]= $value;
							$sums->{ $value }++;
							$i++;
						}
					}
				}
			}
		}
		if (my $value = $self->results->value($record, $self->groupby)){
			if ($value =~ /^\d+$/){
                $mini[$i]= $value;
			    $sums->{ $self->groupby } += $value;
			    $i++;
			}
			elsif ($self->results->value($record, 'count')){
			    $mini[$i]= $value; 
				$sums->{ $self->groupby } += $self->results->value($record, 'count');
				$i++;
			}
			else {
			    $mini[$i]= $value;
				$sums->{$value}++;
				$i++;
			}
#$self->log->trace('Yahoo ' . Dumper($sums));
		}
	}
	
@mini = sort { $a <=> $b } @mini;
my $ret = [];
my $lastindex=$#mini;
foreach my $key (keys %$sums)
{
my $add = $sums->{$key} ;
my $avg = $add/($lastindex+1); 
push @$ret, { _groupby => $key, intval => $avg, _count => $avg};
}
$self->on_transform->(Results::Groupby->new(results => { $self->groupby => [ sort { $b->{intval} <=> $a->{intval} } @$ret ] }));

return $self;
}

 
1;
