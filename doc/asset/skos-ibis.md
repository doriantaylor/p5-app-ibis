# SKOS/IBIS UI

This stylesheet transforms markup specific to SKOS and IBIS.

## skos:footer

This is a UI component for `skos:Concept` (i.e. `ibis:Entity`)-derived
subjects, as well as `skos:ConceptScheme`/`ibis:Network` aggregates.

If it's a concept or derivative thereof (I should really change
`ibis:Entity` to `ibis:Statement`), it has to first find the *scheme* it
belongs to (via `skos:inScheme`, `skos:topConceptOf`, or its inverse,
`skos:hasTopConcept`), otherwise we are currently looking at the scheme.

We then have to determine if the scheme is in *focus*. For this we first
find the `xhv:top` (at least for now; I may come up with a better one
later) relative to the scheme.

Note that there is nothing preventing a conceptual entity from belonging
to zero schemes, or belonging to more than one scheme. There is
furthermore nothing preventing none of the associated schemes from being
in focus, although having more than one scheme in focus is an error.
(This is partly why I have to change the focus mechanism from being
relative to the *space*, to being relative to the *user*, not only
because it can potentially get into this state in a multiuser system,
but also because people will be continually clobbering each other's
state.)

If a concept belongs to zero schemes, we should throw up a modal to
force the user to pick a scheme. We should default to the scheme in
focus. If there are other schemes present, we should provide an option
to set the focus as well as attach the concept. We should provide a
mechanism to create a new scheme (which we assume will attach the
concept). There should be an option (default?) to focus a new scheme.

A concept attached to multiple schemes needs UI to be able to detach
from one scheme, but only if there are multiples.

A concept should also be able to import all of its neighbours into the
scheme

<div class="section" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:html="http://www.w3.org/1999/xhtml"
xmlns:ibis="https://vocab.methodandstructure.com/ibis#"
xmlns:skos="http://www.w3.org/2004/02/skos/core#"
xmlns:cgto="https://vocab.methodandstructure.com/graph-tool#"
xmlns:x="urn:x-dummy:" xmlns:rdfa="http://www.w3.org/ns/rdfa#"
xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
xmlns:str="http://xsltsl.org/string" xmlns:uri="http://xsltsl.org/uri">

### Concept UI

- flyout list of all schemes

  - participating scheme(s) gathered at the top
  - focused scheme at the tippy-top/closed position (if participating)
  - then non-participating schemes, whether focused or not
  - each has a link to the scheme itself
  - unfocused schemes have a set focus button
  - non-participating schemes have attach+set focus, attach+no-focus
    buttons as well

- create new scheme UI

  - text box for name
  - attach concept?
  - if current subject is *not* an `ibis:Entity`, provide toggle between
    `skos:ConceptScheme` and `ibis:Network`
  - go to
  - set focus

</div>

<div class="section" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:html="http://www.w3.org/1999/xhtml"
xmlns:ibis="https://vocab.methodandstructure.com/ibis#"
xmlns:skos="http://www.w3.org/2004/02/skos/core#"
xmlns:cgto="https://vocab.methodandstructure.com/graph-tool#"
xmlns:x="urn:x-dummy:" xmlns:rdfa="http://www.w3.org/ns/rdfa#"
xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
xmlns:str="http://xsltsl.org/string" xmlns:uri="http://xsltsl.org/uri">

### Scheme UI

- schemes do not have to worry about attaching concepts, so when the
  subject location is a scheme, there is only the matter of navigating
  to another one of the listed schemes, or otherwise focusing it (and
  presumably navigating to it as well).
- 

</div>

## skos:footer-option
