(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins":                             "index",
            "NotJenkins/pull/:id":                    "redirectPR",
            "NotJenkins/branch/:id":                  "redirectBranch",
            "NotJenkins/pull/:pullRequestID/builds":  "pullRequestBuilds",
            "NotJenkins/branch/:branchName/builds":   "branchBuilds"
        },

        redirectPR: function (id) {
            this.navigate("NotJenkins/pull/"+id+"/builds", { trigger: true, replace: true });
        },

        redirectBranch: function (id) {
            this.navigate("NotJenkins/branch/"+id+"/builds", { trigger: true, replace: true });
        },

        pullRequestBuilds: function (pullRequestID) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.PageTitle(),
                new NotJenkins.View.Subnav(),
                new NotJenkins.View.PullRequestContent()
            ], function (view, index) {
                view.serialize({
                    pullRequestID: parseInt(pullRequestID, 10)
                });
            });
        },

        branchBuilds: function (branchName) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.PageTitle(),
                new NotJenkins.View.Subnav(),
                new NotJenkins.View.BranchContent()
            ], function (view, index) {
                view.serialize({
                    branchName: branchName
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
