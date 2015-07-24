YAHOO.namespace('YAHOO.ELSA.Chart');
YAHOO.ELSA.Charts = [];
YAHOO.ELSA.Chart = function(){};
YAHOO.ELSA.Chart.registeredCallbacks = {};

YAHOO.ELSA.Chart.open_flash_chart_data = function(p_iId){
    try {
        logger.log('returning chart data for id:' + p_iId, YAHOO.ELSA.Charts[p_iId]);
        return YAHOO.lang.JSON.stringify(YAHOO.ELSA.Charts[p_iId].cfg);
    }
    catch (e){
        logger.log('exception: ' + e);
    }
}

// Auto-graph given a graph type, title, and AoH of data
YAHOO.ELSA.Chart.Auto = function(p_oArgs){
    if (typeof p_oArgs.callback == 'undefined'){
        p_oArgs.callback = function(){};
    }
    YAHOO.ELSA.Chart.registeredCallbacks[p_oArgs.container] = p_oArgs.callback;
    logger.log('given container id: ' + p_oArgs.container);
    var id = YAHOO.ELSA.Charts.length;
    this.id = id;
    this.colorPalette = [ {
        fillColor: "rgba(151,187,205,0.5)",
        strokeColor: "rgba(151,187,205,0.8)",
        highlightFill: "rgba(151,187,205,0.75)",
        highlightStroke: "rgba(151,187,205,1)"
    }, {
        fillColor: "rgba(219,147,175,0.5)",
        strokeColor: "rgba(219,147,175,0.8)",
        highlightFill: "rgba(219,147,175,0.75)",
        highlightStroke: "rgba(219,147,175,1)"
    } ];

    this.type = p_oArgs.type;
    // Scrub nulls
    // Figure out columns using the first row
    var aElements = [];
    var iCounter = 0;
    var iColorPaletteLength = this.colorPalette.length;
    for (var key in p_oArgs.data){
        if (key == 'x'){
            continue;
        }
        var aValues = [];
        for (var i in p_oArgs.data[key]){
            var val = p_oArgs.data[key][i];
            if (typeof val == 'object'){
                var iSum = 0;
                for (var j in p_oArgs.data[key][i]){
                    if (j == 'val'){
                        continue;
                    }
                    logger.log('iSum: ' + iSum + ', j: ' + j + ', val: ' + p_oArgs.data[key][i][j]);
                    iSum = iSum + parseInt(p_oArgs.data[key][i][j]);
                }
                aValues.push(iSum);
            }
            else {
                aValues.push(val);
            }
        }
        var thisColor = this.colorPalette[((iColorPaletteLength - (iCounter % iColorPaletteLength)) - 1)];
        aElements.push({
            fillColor: thisColor.fillColor,
            strokeColor: thisColor.strokeColor,
            highlightFill: thisColor.highlightFill,
            highlightStroke: thisColor.highlightStroke,
            label: key,
            data: aValues
        });
        iCounter++;
    }

    // calculate label steps
    var iXLabelSteps = 1;
    if (p_oArgs.data.x.length > 10){
        iXLabelSteps = parseInt(p_oArgs.data.x.length / 10);
    }
    var aLabels = [];
    for (var i = 0; i < p_oArgs.data.x.length; i += iXLabelSteps){
        aLabels.push(p_oArgs.data.x[i]);
    }

    var chartCfg = {
        title: {
            text:unescape(p_oArgs.title),
            style:'{font-size:16px;}'
        },
        elements: aElements,
        x_axis:{
            labels:{
                labels:p_oArgs.data.x,
                rotate:330,
                'visible-steps': iXLabelSteps
            }
        }
    }
    if (p_oArgs.bgColor){
        chartCfg.bg_colour = p_oArgs.bgColor;
    }
    this.cfg = chartCfg;

    // create a div within the given container so we can append the "Save As..." link
    var outerContainerDiv = YAHOO.util.Dom.get(p_oArgs.container);
    var linkDiv = document.createElement('div');
    linkDiv.id = p_oArgs.container + '_link';
    var saveLink = document.createElement('a');
    saveLink.setAttribute('href', '#');
    saveLink.innerHTML = 'Save Chart As...';
    var aEl = new YAHOO.util.Element(saveLink);
    aEl.on('click', YAHOO.ELSA.Chart.saveImage, this.id);
    linkDiv.appendChild(saveLink);
    outerContainerDiv.appendChild(linkDiv);

    var containerDiv = document.createElement('div');
    containerDiv.id = p_oArgs.container + '_container';
    var canvasEl = document.createElement('canvas');
    canvasEl.id = p_oArgs.container + '_canvas';
    containerDiv.appendChild(canvasEl);
    outerContainerDiv.appendChild(containerDiv);
    this.container = containerDiv.id;

    var ctx = canvasEl.getContext("2d");
    var data = {
        labels: aLabels,
        datasets: aElements
    };

    logger.log('outerContainerDiv', outerContainerDiv);
    try {
        var iWidth = 1000;
        if (p_oArgs.width){
            iWidth = p_oArgs.width;
        }
        var iHeight = 300;
        if (p_oArgs.height){
            iHeight = p_oArgs.height;
        }
        canvasEl.style.height = iHeight + "px";
        canvasEl.style.width = iWidth + "px";
    }
    catch (e){
        YAHOO.ELSA.Error(e);
    }

    function makeChart(ctx, type, data, opts) {
        opts = opts || {};
        if ('bar' == type) {
            return new Chart(ctx).Bar(data, opts);
        }
        return new Chart(ctx).Line(data, opts);
    };

    var chart = makeChart(ctx, this.type, data, {});
    logger.log('element: ', YAHOO.util.Dom.get(this.container));
};

YAHOO.ELSA.Chart.saveImage = function (p_oEvent, p_iId){
    logger.log('save image with id ' + p_iId);
    try {
        var sImageData = YAHOO.util.Dom.get(YAHOO.ELSA.Charts[p_iId].container).get_img_binary();
        var oEl = document.createElement('img');
        oEl.id = 'save_image';
        oEl.src = 'data:image/png;base64,' + sImageData;
        win = window.open('', 'SaveChart', 'left=20,top=20,width=700,height=500,toolbar=0,resizable=1,status=0');
        win.document.body.appendChild(oEl);
    }
    catch (e){
        YAHOO.ELSA.Error(e);
    }
}
