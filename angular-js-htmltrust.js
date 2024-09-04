ctrl.filter("trustHtml", ['$sce', function ($sce) { return function (htmlCode) { return $sce.trustAsHtml(htmlCode); } }]);

// html render in angularjs binding
