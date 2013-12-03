(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins":                             "index",
            "NotJenkins/pull/:pullRequestID":         "redirect",
            "NotJenkins/pull/:pullRequestID/builds":  "builds"
        },

        redirect: function (pullRequestID) {
            this.navigate("NotJenkins/pull/"+pullRequestID+"/builds", { trigger: true, replace: true });
        },

        builds: function (pullRequestID) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.PageTitle(),
                new NotJenkins.View.Subnav(),
                new NotJenkins.View.ContentBuild()
            ], function (view, index) {
                view.serialize({
                    pullRequestID: parseInt(pullRequestID, 10)
                });
            });
        },

        index: function () {
            _.each([
                new NotJenkins.View.CollectionList({ title: "Pull Requests" }),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.Blank({ el: ".subnav.view" }),
                new NotJenkins.View.Blank({ el: ".content.view" }),
                new NotJenkins.View.SectionTitle({ title: "Not Jenkins" }),
                new NotJenkins.View.PageTitle({ title: "Not Jenkins" }),
            ], function (view, index) {
                view.serialize();
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
