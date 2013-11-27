(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins" : "index"
        },

        index: function () {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.CollectionListFooter(),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.Subnav()
            ], function (view, index) {
                view.serialize();
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
