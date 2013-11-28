(function (NotJenkins) {
    "use strict";

    NotJenkins.View = {
        CollectionList: Harbour.View.extend({
            template: "/core/templates/collection-list.html",
            el: ".collection-list.view",

            serialize: function (options) {
                var view = this;
                options = options || {}

                view.render({
                    json: {
                        sectionTitle: view.options.title,
                        sectionRoot: "NotJenkins/pull",
                        sectionActive: options.pullRequestID,
                        models: [
                            {
                                title: "Add tooltips with transefer error messages, fix jshint errors to please Jenkins",
                                id: "668"
                            },
                            {
                                title: "EUCP Unit Testing",
                                id: "685"
                            }
                        ]
                    }
                })
            }
        }),

        Blank: Harbour.View.extend({ template: "" }),

        SectionTitle: Harbour.View.extend({
            template: "/core/templates/header.html",
            el: ".section-title.view",

            serialize: function () {
                var view = this;

                view.render({
                    json: {
                        title: view.options.title
                    }
                });
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
                                url: "home",
                                icon: "home",
                                title: "Home"
                            },
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

            serialize: function () {
                var view = this;

                view.render({
                    json: {}
                });
            }
        }),

        ContentHome: Harbour.View.extend({
            template: "/modules/NotJenkins/templates/content-home.html",
            el: ".content.view",

            serialize: function () {
                var view = this;

                view.render({
                    json: {}
                });
            }
        }),
    };

})(Harbour.Module.register("NotJenkins"));
