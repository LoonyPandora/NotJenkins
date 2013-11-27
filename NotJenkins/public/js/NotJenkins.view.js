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
        })
    };

})(Harbour.Module.register("NotJenkins"));
