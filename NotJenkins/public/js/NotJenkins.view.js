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
                        sectionRoot: "NotJenkins/build",
                        models: [
                            {title: "Footbar", id: "12345"}
                        ]
                    }
                })
            }
        }),

        CollectionListFooter: Harbour.View.extend({
            template: "",
            el: ".collection-list-footer.view",

            serialize: function () {
                var view = this;

                view.render({
                    json: "hello"
                });
            }
        }),

        SectionTitle: Harbour.View.extend({
            template: "/core/templates/header.html",
            el: ".section-title.view",

            serialize: function () {
                var view = this;

                view.render({json: {
                    title: "Not Jenkins"
                }});
            }
        }),

        Subnav: Harbour.View.extend({
            template: "/core/templates/subnav.html",
            el: ".subnav.view",

            serialize: function () {
                var view = this;

                view.render({
                    json: {
                        sections: [
                            {
                                url: "foo",
                                icon: "dot-circle-o",
                                title: "Things"
                            }
                        ]
                    }
                });
            }
        }),
        
    };

})(Harbour.Module.register("NotJenkins"));
