(function (NotJenkins) {
    "use strict";

    NotJenkins.View = {
        CollectionList: Harbour.View.extend({
            template: "/core/templates/collection-list.html",
            el: ".collection-list.view",

            serialize: function () {
                var view = this;

                view.render({
                    json: {
                        sectionTitle: "Builds",
                        sectionRoot: "NotJenkins/pull",
                        models: [
                            {
                                title: "Add tooltips with transefer error messages, fix jshint errors to please Jenkins",
                                id: "668"
                            }
                        ]
                    }
                })
            }
        }),

        CollectionListFooter: Harbour.View.extend({
            template: "",
            el: ".collection-list-footer.view",
        }),

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

                var baseURL = Backbone.history.fragment;
                if (baseURL.indexOf("/") !== -1) {
                    baseURL = baseURL.substring(0, baseURL.lastIndexOf("/"));
                }

                view.render({
                    json: {
                        sectionRoot: baseURL,
                        sections: [
                            {
                                url: "home",
                                icon: "home",
                                active: "active",
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
        
    };

})(Harbour.Module.register("NotJenkins"));
