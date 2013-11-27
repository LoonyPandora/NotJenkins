(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins" : "index"
        },

        index: function () {
            _.each([
                new NotJenkins.View.CollectionList()
            ], function (view, index) {
                view.serialize();
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
