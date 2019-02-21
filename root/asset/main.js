var NS = {
    'ibis': 'https://privatealpha.com/ontology/ibis/1#'
};

var OTHER = {
    'rdf-type':   'rdf:type :',
    'rdf:type :': 'rdf-type'
};

function expand (curie) {
    var parts = curie.split(':', 2);
    if (parts && parts.length > 0 && NS[parts[0]])
        return NS[parts[0]] + parts[1];
    return curie;
}

function abbreviate (uri) {
    for (k in NS) {
        if (uri.startsWith(NS[k])) {
            return k + ':' + uri.substring(NS[k].length);
        }
    }
    return uri;
}

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

function toggleForm (input) {
    var name  = input.name;
    var value = input.value;
    var form  = $(input.form);
    var other = OTHER[name];

    //console.log(form);
    //alert(value);

    /* disable all the other controls */

    if (other) {
        /* set the value and let  */
        var node = $("input[name='" + other + "']");
        var sel  = node.filter("*[value='" + value + "']");

        /* we have to select by checking the value of the other node */
        if (!sel.prop('checked')) {
            node.each(function () { this.checked = false; });
            //alert(n.length);
            sel.prop('checked', true);
            sel.trigger('change');
        }
        else {
            //alert(sel.prop('checked'));
        }
    }
    else {
        alert('wat ' + name);
    }
}

function toggleSelect (input) {
    var value = input.value;
    var form  = $(input.form);
    var uri   = expand(value);
    /*
    console.log("hi " + uri);
    console.log(form);
    */

    form.find("fieldset.relation").each(function () {
        //console.log(this.getAttribute('about'), value);
        $(this).toggleClass('selected', this.getAttribute('about') == value);
    });

    form.find("optgroup[rev~='rdf:type']").each(function () {
        var th = $(this);
        var opts = th.find("option:selected");
        if (th.attr('about') == uri) {
            // 
            if (opts.length == 0) {
                opts = th.find("option");
                if (opts.length > 0) opts.first().prop('selected', true);
            }
                
            th.show();
        }
        else {
            opts.prop('selected', false);
            th.hide();
        }
    });
    var forms = $("#create-new, #connect-existing, #toggle-which").each(
        //forms.find('fieldset.edit-group').each(function () {
        function () {
            this.setAttribute('about', value);
        });
}

function toggleCheckBox (input) {
    var val  = input.checked;
    var re   = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g;
    var name = input.name.replace(re, '').replace(/[\s\uFEFF\xA0]+/g, ' ');
    var about = input.parentNode.parentNode.getAttribute('about');

    var names = [];
    if (name.startsWith('!')) {
        names[0] = name.replace(/^\!\s*/, '');
        names[1] = name;
    }
    else {
        names[0] = name;
        names[1] = '! ' + name;
    }

    var selectors = [];
    for (var n in names) {
        selectors.push("input[type=checkbox][name='" + names[n] + "']");
    }

    //console.log(selectors.join(', '));

    var forms = $("#create-new, #connect-existing");
    forms.find(selectors.join(', ')).each(function () {
        $(this.parentNode.parentNode).toggleClass('selected', !!val);
        if (this != input) this.checked = val;
    });

    /* forms.find('fieldset.edit-group').each(function () {
        this.setAttribute('rel', about);
    });*/
}


$(document).ready(function () {
    /* check initial state */

    switchForm($("input[name='new-item']:checked").val());

    /* attach toggle event to toggle buttons */
    $("input[name='new-item']").change(function () { switchForm(this.value); });

    /* "create new" form likewise */
    //$("#create-new .type-toggle").change(function () { toggleForm(this); });

    /* the "connect existing" form needs a little extra something */
    $("#create-new .type-toggle, #connect-existing .type-toggle").change(
        function () {
            toggleForm(this);
            toggleSelect(this);
        }
    );

    /* add the toggle to the checkboxes */
    $("#create-new, #connect-existing").find("input[type=checkbox]").change(
        function () { toggleCheckBox(this); } );

    /* */
    $('.type-toggle:checked').first().trigger('change');
});

function toggleFullscreen () {
    var doc = this.ownerDocument;
    if (doc.fullscreenElement || doc.webkitfullScreenElement
        || doc.msFullscreenElement) {
        console.log('full screen');
        if (doc.exitFullscreen) {
            doc.exitFullscreen();
        }
        else if (doc.mozExitFullscreen) {
            doc.mozExitFullscreen();
        }
    }
    else {
        console.log('not full screen');
        if (doc.body.requestFullscreen) {
            doc.body.requestFullscreen();
        }
        else if (doc.body.mozRequestFullscreen) {
            doc.body.mozRequestFullscreen();
        }
    }
}

window.addEventListener('load', function () {
    /*
    var butt = document.getElementById('toggle-full-screen');
    if (butt && document.fullscreenEnabled) {
        butt.style.display = 'initial';
        butt.toggleFullscreen = toggleFullscreen;
        butt.addEventListener('click',
                              function () { this.toggleFullscreen(); }, false);
    }
    */
    /*
    document.body.addEventListener('toggle-full-screen', function (e) {
        return true;
    }, false);

    document.body.addEventListener('touchstart', function (e) {
        if (!this.longPressTimer) {
            this.longPressTimer = null;
            this.longPressTimer = window.setTimeout(function () {
                var ev = new Event('toggle-full-screen');
                document.body.dispatchEvent(ev);
            }, 500);
        }
        return true;
    }, false);

    document.body.addEventListener('touchend', function (e) {
        if (this.longPressTimer) {
            console.log('clearing');
            window.clearTimeout(this.longPressTimer);
            this.longPressTimer = null;
        }
        return true;
    }, false);
    */
    return true;
}, false);
