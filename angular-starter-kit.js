// angular model setup
// this code is defines the app's namespace and identifies a set of dependencies (namespaces)
var mainApp = angular.module('glennapp', ['glenncontrollers', 'glennservices'])

// this is a filter to be used against some data set with a 'Title' property.
mainApp.filter('gadgetsFilter', function () {
	// returns a predicate, given a set and a query
    return function (ds, query) {

    	// if the query is not, return entire dataset as is.
        if (!query) {
            return ds;
        }

        var filtered = [];
        // case insensitive compare here.
        query = query.toLowerCase();
        // for each item in the set, determine if it meets the criteria.
        angular.forEach(ds, function (i) {
        	// assuming each item in the set has a Title field.
        	// for this comparison you need to roll your own.
            if (i.Title.toLowerCase().indexOf(query) !== -1) {
                filtered.push(i);
            }
        });

        // return filtered dataset
        return filtered;
    }
});

// define the services namespace, include a dependency on ng-resource
var glennService = angular.module('glennservices', ['ngResource']);
// define a controllers namespace, no dependencies
var glennControllers = angular.module('glennControllers', []);

// define a service called 'Gadgets', which uses ng-resource,
// and has a 'query' method that takes no args and returns an array.
// the client sends a POST request to the endpoint: /data/gadgets
glennService.factory('Gadgets', ['$resource',
    function ($resource) {
        return $resource('/Data/Gadgets', {}, {
            query: { method: 'POST', params: {}, isArray: true }
        });
    }]);

// defines a controller to provide data for a gadget list.
// has dependencies on the $scope (view-model) and the Gadgets service.
glennControllers.controller('gadgetListController',
    ['$scope', 'Gadgets',
        function ($scope, Gadgets) {
        	// define a local array to hold the result of the service call.
            var gadgets = [];
            
            // execute the service call Gadgets.query
            // the only argument is a callback function with a single arg: data
            Gadgets.query(function (data) {
            	// for each 'gadget' data-item that we get back from the service call...
                angular.forEach(data, function (g) {
                	// define a function on that item to enable the client to 'bid'
                    g.bid = function () {
                        //debugger;
                        bids.server.placeBid(this.Title);
                    }
                    // define a function to calculate the max bid amount
                    g.maxBidAmount = function () {
                        var amt = 0;
                        for (var q = 0; q < g.Bids.length; q++) {
                            if (g.Bids[q].BidAmount > amt) {
                                amt = g.Bids[q].BidAmount;
                            }
                        }
                        return "$" + amt.toString();
                    }
                    // add the item to the local array.
                    gadgets.push(g);
                }); // end: foreach

                // add the local array to the viewmodel ($scope) with the name gadgets
                $scope.gadgets = gadgets;
            }); // end: Gadget.query

        }]); // end: controller definition
