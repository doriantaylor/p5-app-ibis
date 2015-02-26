var NS = {
    'ibis': 'http://privatealpha.com/ontology/ibis/1#'
}

var OTHER = {
    'rdf-type':   'rdf:type :',
    'rdf:type :': 'rdf-type'
};

function switchForm (isNew) {
    isNew = !!isNew;
    if (isNew) {
        $('#connect-existing').hide();
        $('#create-new').show();
        //alert(which);
    }
    else {
        $('#create-new').hide();
        $('#connect-existing').show();
    }
    //alert(which.val());
}

//function toggleForm (value, name) {
function toggleForm (input) {
    var name  = input.name;
    var value = input.value;
    var form  = $(input.form);
    console.log(form);
    //alert(value);
    var other = OTHER[name];

    /* disable all the other controls */

    if (other) {
        /* set the value and let  */
        var node = $("input[name='" + other + "']");
        var sel  = node.filter("*[value='" + value + "']");

        /* we have to select by checking the value of the other node */
        if (!sel.prop('checked')) {
            node.each(function () { this.checked = false });
            //alert(n.length);
            sel.prop('checked', true);
        }
        else {
            //alert(sel.prop('checked'));
        }
    }
    else {
        alert('wat ' + name);
    }
}

//function toggleSelect (


$(document).ready(function () {
    /* check initial state */

    switchForm($("input[name='new-item']:checked").val());

    //alert($("input[name='rdf-type']:checked"));
    //alert($("input[name='rdf:type :']:checked"));

    $("input[name='new-item']").change(function () { switchForm(this.value) });
    $(".type-toggle").change(function () {
        toggleForm(this) });
});
