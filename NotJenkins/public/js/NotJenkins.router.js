(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins" : "index",
            "NotJenkins/pull/:pullRequest" : "redirect",
            "NotJenkins/pull/:pullRequest/home" : "pull"
        },

        redirect: function (pullRequest) {
            this.navigate("NotJenkins/pull/"+pullRequest+"/home", { trigger: true, replace: true });
        },

        pull: function (pullRequest) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.CollectionListFooter(),
                new NotJenkins.View.SectionTitle({ title: "Pull Request #"+pullRequest }),
                new NotJenkins.View.Subnav()
            ], function (view, index) {
                view.serialize();
            });
        },

        index: function () {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.CollectionListFooter(),
                new NotJenkins.View.SectionTitle({ title: "Not Jenkins" }),
                new NotJenkins.View.Subnav()
            ], function (view, index) {
                view.serialize();
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
