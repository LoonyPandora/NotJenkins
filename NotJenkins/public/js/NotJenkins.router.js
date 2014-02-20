(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins":                                       "index",
            "NotJenkins/settings":                              "settings",
            "NotJenkins/job/:jobID":                            "job",
            "NotJenkins/repo/:owner/:repo/pull/:pullRequestID": "pull",
            "NotJenkins/repo/:owner/:repo/branch/*branchName":  "branch", // branch names can contain slashes
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
        },

        settings: function () {
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
        },

        job: function () {
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
        },

        pull: function (owner, repo, pullRequestID) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.PageTitle(),
                new NotJenkins.View.Blank({ el: ".subnav.view" }),
                new NotJenkins.View.PullRequestContent()
            ], function (view, index) {
                view.serialize({
                    owner: owner,
                    repo: repo,
                    pullRequestID: parseInt(pullRequestID, 10)
                });
            });
        },

        branch: function (owner, repo, branchName) {
            _.each([
                new NotJenkins.View.CollectionList(),
                new NotJenkins.View.Blank({ el: ".collection-list-footer.view" }),
                new NotJenkins.View.SectionTitle(),
                new NotJenkins.View.PageTitle(),
                new NotJenkins.View.Blank({ el: ".subnav.view" }),
                new NotJenkins.View.BranchContent()
            ], function (view, index) {
                view.serialize({
                    owner: owner,
                    repo: repo,
                    branchName: branchName
                });
            });
        }
    });

})(Harbour.Module.register("NotJenkins"));
