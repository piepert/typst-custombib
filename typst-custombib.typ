#import "typst-custombib-generator.typ": *

#let ifnotnone(elem, fn-true, fn-false: k => none) = if elem != none {
    fn-true(elem)
} else {
    fn-false(elem)
}

#let ifhaskey(elem, key, fn-true, ..k) = if elem.at(key, default: none) != none {
    fn-true(elem)
} else if k.pos().len() > 0 {
    k.pos().first()(elem)
}

#let get-bibliography-data(location) = {
    return TCBSTATES.data.at(location)
}

#let load-bibliography(path) = {
    let data = yaml(path)

    for entry in data.keys() {
        if "entry-type" not in data.at(entry) {
            return strong(text(red, [`entry-type` NEEDS TO BE SET IN #entry.]))

        } else if data.at(entry).at("entry-type") == "custom" {
            // return strong(text(red, [#get-option(location, "styles", "custom", "sort-by") NEED TO BE SET IN #entry.]))
            // need to check if all custom items have the field set in styles.custom.sort-by, but later when generating the bibliography

        } else if "title" not in data.at(entry) or "author" not in data.at(entry) {
            return strong(text(red, [`author` AND `title` NEED TO BE SET IN #entry.]))
        }

        for k in data.at(entry).keys() {
            if type(data.at(entry).at(k)) == "integer" {
                data.at(entry).at(k) = str(data.at(entry).at(k))
            }
        }
    }

    TCBSTATES.data.update(data)
    TCBSTATES.used-citations.update(())
    TCBSTATES.citation-history.update(())
    TCBSTATES.last-citation.update(())
}

#let tcb-bibliography(path) = {
    load-bibliography(path)
}

#let tcb-show-bibliography() = {
    locate(loc => generate-bibliography(loc,
        TCBSTATES.style.at(loc),
        TCBSTATES.data.at(loc),
        TCBSTATES.used-citations.at(loc)))
}

#let tcb-style(data) = {
   TCBSTATES.style.update(data)
}

#let tcb-has-key(location, key) = {
    return key in TCBSTATES.data.at(location)
}

#let tcb-cite(key, postfix: none, prefix: none, wrap-single: true) = {
    TCBSTATES.last-citation.update(key)
    TCBSTATES.citation-history.update(k => (k, key).flatten())
    TCBSTATES.used-citations.update(k => if key not in k {
        (k, key).flatten()
    } else {
        k
    })

    locate(loc => {
        let wrapper = e => e
        if has-option(loc, "inline.wrap-any") and wrap-single {
            wrapper = get-option(loc, "inline.wrap-any")
        }

        wrapper(generate-citation-inline(loc,
            TCBSTATES.style.at(loc),
            TCBSTATES.data.at(loc),
            key,
            postfix: postfix,
            prefix: prefix))
    })
}

#let tcb-cites(..keys) = {
    let keys = keys.pos()

    locate(loc => {
        let wrapper = e => e
        if has-option(loc, "inline.wrap-any") {
            wrapper = get-option(loc, "inline.wrap-any")
        }

        if not has-option(loc, "options.separator") {
            return strong(text(red, [NEEDS options.separator!]))
        }

        let sep = get-option(loc, "options.separator")
        let content = []

        for i in range(0, keys.len()) {
            content += tcb-cite(keys.at(i), wrap-single: false)

            if i+1 < keys.len() {
                content += eval("["+sep+"]")
            }
        }

        let styler = get-option(loc, "inline.wrap-multi")
        if type(styler) != "content" { // IF NOT ERROR
            return wrapper(styler(content))
        }

        wrapper(content)
    })
}