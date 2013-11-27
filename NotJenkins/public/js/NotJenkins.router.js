(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins":                             "index",
            "NotJenkins/pull/:pullRequestID":         "redirect",
            "NotJenkins/pull/:pullRequestID/home":    "home",
            "NotJenkins/pull/:pullRequestID/builds":  "builds"
        },

        redirect: function (pullRequestID) {
            this.navigate("NotJenkins/pull/"+pullRequestID+"/home", { trigger: true, replace: true });
        },

        builds: function (pullRequestID) {
            _.each([
                new NotJenkins.View.CollectionList({ title: "Pull Requests" }),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle({ title: "Pull Request #"+pullRequestID+" - Build List" }),
                new NotJenkins.View.Subnav()
            ], function (view, index) {
                view.serialize({
                    pullRequestID: pullRequestID
                });
            });
        },

        home: function (pullRequestID) {
            _.each([
                new NotJenkins.View.CollectionList({ title: "Pull Requests" }),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle({ title: "Pull Request #"+pullRequestID }),
                new NotJenkins.View.Subnav()
            ], function (view, index) {
                view.serialize({
                    pullRequestID: pullRequestID
                });
            });
        },

        index: function () {
            _.each([
                new NotJenkins.View.CollectionList({ title: "Pull Requests" }),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.Blank({ el: ".subnav.view" }),
                new NotJenkins.View.SectionTitle({ title: "Not Jenkins" }),
            ], function (view, index) {
                view.serialize();
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
