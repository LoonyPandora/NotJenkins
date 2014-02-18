(function (NotJenkins) {
    "use strict";

    NotJenkins.View = {
        CollectionList: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/collection-list.html",
            el: ".collection-list.view",

            serialize: function (options) {
                var view = this;
                options = options || {};

                var collection = new NotJenkins.Collection.Builds();

                collection.fetch().done(function () {
                    // TODO: Why am I getting an array back?
                    var builds = collection.toJSON()[0];

                    view.render({
                        json: {
                            repo: options.repo,
                            owner: options.owner,
                            sectionActive: options.pullRequestID || options.branchName,
                            branches: builds.branches,
                            pull_requests: builds.pull_requests,
                        }
                    })
                });
            }
        }),

        Blank: Harbour.View.extend({ template: "" }),

        SectionTitle: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/header.html",
            el: ".section-title.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                if (options.title) {
                    return view.render({
                        json: {
                            title: options.title
                        }
                    });
                }

                var model;
                if (options.pullRequestID) {
                    model = new NotJenkins.Model.PullRequest({
                        github_number: options.pullRequestID
                    });
                } else if (options.branchName) {
                    model = new NotJenkins.Model.Branch({
                        branch_name: options.branchName
                    });
                }

                model.fetch().done(function () {
                    var json = model.toJSON();

                    // We are on a branch
                    if (json.github_title) {
                        json.title = json.github_title;
                        json.github_link = "/"+json.pull+"/"+json.github_number;
                    } else {
                        json.title = json.branch_title;
                        json.github_link = "/tree/"+json.branch_hane;
                    }

                    view.render({
                        json: json
                    });
                })
            }
        }),

 
        PageTitle: Harbour.View.extend({
            template: "/core/templates/header.html",
            el: "title.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                if (options.title) {
                    return view.render({
                        json: {
                            title: options.title
                        }
                    });
                }

                var model;
                if (options.pullRequestID) {
                    model = new NotJenkins.Model.PullRequest({
                        github_number: options.pullRequestID
                    });
                } else if (options.branchName) {
                    model = new NotJenkins.Model.Branch({
                        branch_name: options.branchName
                    });
                }


                model.fetch().done(function () {
                    var json = model.toJSON();

                    json.title = json.github_title || json.branch_title;

                    view.render({
                        json: json
                    });
                })
            }
        }),
 
        Subnav: Harbour.View.extend({
            template: "/core/templates/subnav.html",
            el: ".subnav.view",

            serialize: function () {
                var view = this;

                var fragment = Backbone.history.fragment;
                var baseURL, activeSection;
                if (fragment.indexOf("/") !== -1) {
                    baseURL = fragment.substring(0, fragment.lastIndexOf("/"));
                    activeSection = fragment.substring(fragment.lastIndexOf("/") + 1);
                }

                view.render({
                    json: {
                        sectionRoot: baseURL,
                        sectionActive: activeSection,
                        sections: [
                            {
                                url: "builds",
                                icon: "cogs",
                                title: "Builds"
                            }
                        ]
                    }
                });
            }
        }),

        PullRequestContent: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/pull-request-content.html",
            el: ".content.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                var model = new NotJenkins.Model.PullRequest({
                    github_number: options.pullRequestID
                });

                model.fetch().done(function () {
                    var json = model.toJSON();

                    view.render({
                        json: json
                    });
                })
            }
        }),

        BranchContent: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/branch-content.html",
            el: ".content.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                var model = new NotJenkins.Model.Branch({
                    branch_name: options.branchName
                });

                model.fetch().done(function () {
                    var json = model.toJSON();

                    view.render({
                        json: json
                    });
                })

            }
        }),

    };

})(Harbour.Module.register("NotJenkins"));
