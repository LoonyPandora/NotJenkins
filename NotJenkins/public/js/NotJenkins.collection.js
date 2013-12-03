(function (NotJenkins) {
    "use strict";

    NotJenkins.Collection = {
        Builds: Harbour.Collection.extend({
            model: NotJenkins.Model.Builds,
            url: "/api/NotJenkins/builds"
        })
    };

})(Harbour.Module.register("NotJenkins"));
