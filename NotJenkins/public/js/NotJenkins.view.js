(function (NotJenkins) {
    "use strict";

    NotJenkins.View = {
        CollectionList: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/collection-list.html",
            el: ".collection-list.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                var collection = new NotJenkins.Collection.Builds();

                collection.fetch().done(function () {
                    // TODO: Why am I getting an array back?
                    var builds = collection.toJSON()[0];

                    view.render({
                        json: {
                            sectionActive: options.pullRequestID,
                            branches: builds.branches,
                            pull_requests: builds.pull_requests
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

                if (view.options.title) {
                    view.render({
                        json: {
                            github_title: view.options.title
                        }
                    });
                }

                var model = new NotJenkins.Model.PullRequest({
                    github_number: options.pullRequestID
                });

                model.fetch().done(function () {
                    view.render({
                        json: model.toJSON()
                    });
                })
            }
        }),

 
        PageTitle: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/header.html",
            el: "title.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                if (view.options.title) {
                    view.render({
                        json: {
                            github_title: view.options.title
                        }
                    });
                }

                var model = new NotJenkins.Model.PullRequest({
                    github_number: options.pullRequestID
                });

                model.fetch().done(function () {
                    view.render({
                        json: model.toJSON()
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

        ContentBuild: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/content-build.html",
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

    };

})(Harbour.Module.register("NotJenkins"));
