(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "NotJenkins":                                       "index",
            "NotJenkins/settings":                              "index",
            "NotJenkins/job/:jobID":                            "index",
            "NotJenkins/repo/:owner/:repo/pull/:pullRequestID": "pullRequestBuilds",
            "NotJenkins/repo/:owner/:repo/branch/*branchName":  "branchBuilds", // branch names can contain slashes
        },

        pullRequestBuilds: function (owner, repo, pullRequestID) {
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

        branchBuilds: function (owner, repo, branchName) {
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
