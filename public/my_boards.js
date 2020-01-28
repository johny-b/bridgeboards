var mb = angular.module('myBoards', ['pascalprecht.translate', 'ngCookies']);
mb.config(function($locationProvider, $httpProvider, $compileProvider, $translateProvider) {
    $locationProvider.html5Mode({
        enabled: true,
        requireBase: false,
    });
    $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded';
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|file|ftp|blob):|data:image\//);
    $translateProvider
        .registerAvailableLanguageKeys(['en', 'pl'], {
                         'en*': 'en',
                         'pl*': 'pl'
         })
        .determinePreferredLanguage()
        .fallbackLanguage('en')
        .useSanitizeValueStrategy('escape')
        .useLocalStorage()
        .useStaticFilesLoader({
            prefix: '/translations/main-',
            suffix: '.json'
        });
});

mb.controller('myBoards', function($scope, $http, $translate) {

    $scope.languages = [
          {id: 'pl', name: 'polski / Polish'},
          {id: 'en', name: 'English / angielski'}
    ];
    $scope.language = {id: $translate.proposedLanguage()};
    $scope.changeLanguage = function() {
        $translate.use($scope.language.id);
    };
	$scope.url	  		= '';
	$scope.error		= '';
    $scope.loading = false;
	$scope.$watch( 'url', function(){
		$scope.error = '';
	});
	$scope.galleries	= localStorage.galleries ? JSON.parse(localStorage.galleries) : [];
	$scope.submit 		= function(){
        $scope.loading = true;

		$http({
			method: "POST",
			url:	"getGalleryData",
			headers: {'Content-Type': 'application/x-www-form-urlencoded'},
			data: 	encodeURIComponent(JSON.stringify({
				url: $scope.url,
			})),
		}).then(function(response){
			if ( response.data.error ) {
				$scope.error = response.data.error;
                $scope.loading = false;
			}
			else {
				var gallery = response.data;
				$http({
					method: "POST",
					url:	"http://mywebary.com/api/newGallery",
					headers: {'Content-Type': 'application/x-www-form-urlencoded'},
					data: encodeURIComponent(JSON.stringify(gallery)),
				}).then(function(response){
					$scope.galleries.push({
						url: response.data.url,
						name: gallery.name,
					});
					//$scope.url = '';
                    localStorage.galleries = JSON.stringify($scope.galleries);
                    $scope.error = "";
                    $scope.loading = false;
				}, function(errorResponse) {
                    $scope.error = "Błąd komunikacji z serwerem MyWebary";
                    $scope.loading = false;
                });
			}
		}, function(errorResponse) {
            $scope.error = "Coś poszło nie tak:("
            $scope.loading = false;
        });
	};

});
