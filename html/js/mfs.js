var mfsFileList;
var mfsResponseList;
var mfsResponseCount;
var mfsIndex;
var mfsNotFound;
var mfsDone;

function mfsInit(notfound) {
	mfsFileList=new Array()
	mfsResponseList=new Array();
	mfsIndex = 0;
	mfsExpectedResponseCount = 0;
	mfsResponseCount = 0;
    mfsNotFound = notfound === undefined ? null : notfound;
}

function mfsFinished() {
	if ( mfsResponseCount == mfsFileList.length ) {
		mfsDone();
	}
	
}

function mfsWebCall(url,i) {
    $.ajax({
           url: url,
           global: false,
           dataType: 'json',
           success: function(data) {
           var index = i;
           mfsResponseCount++;
           mfsResponseList[i] = data;
           mfsFinished();
           }}).error(function(xhr) {
                     if ( xhr.status == 404 && mfsNotFound != null ) {
                     mfsResponseCount++;
                     mfsResponseList[i] = jQuery.extend({}, mfsNotFound);
                     mfsFinished();
                     return;
                     }
                     
                     handleAjaxError(null, xhr, null, "Error while retrieving file" );
                     });
}

function mfsGo(finished) {
	mfsDone = finished;
    
	for( var i in mfsFileList ) {
		url = mfsFileList[i];
		mfsWebCall(url,i);
	}
}

