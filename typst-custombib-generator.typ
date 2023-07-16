#import "remove-accents.typ": remove-accents

#let TCBSTATES = (
    last-citation: state("tcb-last-citation"),
    used-citations: state("tcb-bibliography-citations-used"),
    citation-history: state("tcb-bibliography-citation-history"),
    data: state("tcb-bibliography-data"),
    style: state("tcb-bibliography-style")
)

#let parse-name(name) = {
    let splits = name.replace("\\ ", "<SPACE>").split(" ")
    let first = none
    let middle = none
    let last = none

    if splits.len() == 1 {
        last = splits.at(0)

    } else if splits.len() == 2 {
        first = splits.at(0)
        last = splits.at(1)

    } else if splits.len() > 2 {
        first = splits.first()
        last = splits.last()
        middle = splits.slice(1, splits.len()-1).join(" ")
    }

    (first: if first != none { first.replace("<SPACE>", " ") },
        middle: if middle != none { middle.replace("<SPACE>", " ") },
        last: if last != none { last.replace("<SPACE>", " ") })
}

#let parse-names(names) = {
    if type(names) == "array" {
        names.map(e => parse-name(e))

    } else {
        (parse-name(names),)
    }
}

#let get-option(location, keys) = {
    let keys = keys.split(".")
    let style = TCBSTATES.style.at(location)

    for key in keys {
        if key in style or type(style) != "dictionary" {
            style = style.at(key)

        } else {
            return strong(text(red, [OPTION #(keys.join(".")) NOT FOUND!]))
        }
    }

    return style
}

#let has-option(location, keys) = {
    let keys = keys.split(".")
    let style = TCBSTATES.style.at(location)

    for key in keys {
        if key in style or type(style) != "dictionary" {
            style = style.at(key)

        } else {
            return false
        }
    }

    return true
}

#let generate-citation(location,
    style,
    bib-data,
    key,
    postfix: none,
    prefix: none,
    citation-position: "inline") = {

    // for custom run custom
    // format-by-entry-type(format-fields(entry))
    // ...

    let bib-data = TCBSTATES.data.at(location)
    let style = TCBSTATES.style.at(location)

    if bib-data == none or style == none {
        panic("bibliography error!")
    }

    let entry = bib-data.at(key, default: none)

    let format = get-option(location, citation-position+".format")
    let mutator = get-option(location, citation-position+".mutator")

    if type(format) == "content" {
        return format
    }

    if entry == none {
        return strong(text(red, [KEY #key NOT FOUND!]))
    }

    entry.insert("postfix", postfix)
    entry.insert("prefix", prefix)

    if type(mutator) != "content" {
        entry = mutator(entry)
    }

    if entry.entry-type == "custom" {
        let styler = get-option(location, "custom."+citation-position)

        if type(styler) == "content" {
            return styler // is error
        }

        return format(entry, styler(entry))
    }

    let fallback = get-option(location, citation-position+".types.fallback")
    let styler = get-option(location, citation-position+".types."+entry.entry-type)

    let citation = (:)

    if type(fallback) == "content" {
        return fallback // is error
    }

    let author = if has-option(location, citation-position+".fields.author") {
        get-option(location, citation-position+".fields.author")
    } else {
        get-option(location, "fields.author")
    }

    let authors = get-option(location, "fields.authors")

    if type(authors) != "content" { // NO ERROR, STYLE AUTHORS
        citation.insert("authors", authors(entry, parse-names(entry.author)
            .map(e => if type(author) == "content" {
                e
            } else {
                author(entry, e)
            })))
    }

    for field in entry.keys() {
        if field == "author" {
            continue
        }

        let fallback = get-option(location, "fields.fallback")
        let styler = if has-option(location, citation-position+".fields."+field) {
            get-option(location, citation-position+".fields."+field)
        } else {
            get-option(location, "fields."+field)
        }

        if type(fallback) == "content" {
            return fallback
        }

        if type(styler) == "content" {
            citation.insert(field, fallback(entry, entry.at(field)))
        } else {
            citation.insert(field, styler(entry, entry.at(field)))
        }
    }

    format(entry, if type(styler) == "content" {
        fallback(entry, citation)
    } else {
        styler(entry, citation)
    })
}

#let generate-citation-inline(location,
    style,
    bib-data,
    key,
    postfix: none,
    prefix: none) = {

    generate-citation(location,
        style,
        bib-data,
        key,
        postfix: postfix,
        prefix: prefix,
        citation-position: "inline")
}

#let generate-citation-bibliography(location,
    style,
    bib-data,
    key,
    postfix: none,
    prefix: none) = {

    generate-citation(location,
        style,
        bib-data,
        key,
        postfix: postfix,
        prefix: prefix,
        citation-position: "bibliography")
}

#let get-sorter(location, object) = {
    if object.at("entry-type") == "custom" {
        let s = get-option(location, "custom.sort-by")

        if type(s) == "content" {
            return s
        }

        return object.at(s, default: strong(text(red, [THE SORT-BY FACTOR #s IS NOT IN #object.key!])))
    }

    let names = parse-names(object.at("author"))

    return remove-accents(if "author-sorter" in object { object.author-sorter } else { names.map(name => name.last+", "+name.first+" "+name.middle).join("; ", last: " & ") } + ": " + object.at("title") + ". " + object.at("year"))
}

#let generate-bibliography(location,
    style,
    bib-data,
    used) = {

    heading(get-option(location, "options.title"))
    let used = ("none": (section: none, heading: none, used: ()))

    let sections = get-option(location, "sections")
    if type(sections) == "content" {
        return sections // is an error
    }

    let show-sections = get-option(location, "options.show-sections")
    if type(show-sections) == "content" {
        return show-sections // is error
    }

    for s in sections.keys() {
        used.insert(s, (section: s, heading: sections.at(s), used: ()))
    }

    let bib-data = TCBSTATES.data.at(location)
    for key in TCBSTATES.used-citations.at(location) {
        let entry = bib-data.at(key, default: none)

        if entry == none {
            return strong(text(red, [KEY #key NOT FOUND!]))
        }

        entry.insert("key", key)
        let sorter = get-sorter(location, entry)

        if type(sorter) == "content" {
            return sorter
        }

        let sec-key = entry.at("section", default: "none")
        let arr = used.at(sec-key).used

        arr.push((
            key: key,
            sort-by: sorter,
            entry: entry
        ))

        if not show-sections {
            for e in arr {
                used.at("none").used.push(e)
            }
        } else {
            used.at(sec-key).used = arr
        }
    }

    let splitter = "\\#"
    let unsectioned-citations = used.at("none", default: ())
            .used
            .map(e => e.sort-by+splitter+e.key)
            .sorted()
            .map(e => par(hanging-indent: 1.5em,
                generate-citation(location,
                    TCBSTATES.style.at(location),
                    TCBSTATES.data.at(location),
                    e.split(splitter).last(), // key
                    citation-position: "bibliography")))

    if unsectioned-citations.len() > 0 {
        stack(dir: ttb,
            spacing: 1em,
            ..unsectioned-citations)
    }

    if show-sections {
        for s in used.keys() {
            let used = used.at(s)

            if used.section == none {
                continue
            }

            if used.used.len() > 0 {
                heading(level: 2, eval("["+used.heading+"]"))

                stack(dir: ttb,
                    spacing: 1em,
                    ..used.used
                        .map(e => e.sort-by+splitter+e.key)
                        .sorted()
                        .map(e => par(hanging-indent: 1.5em,
                            generate-citation(location,
                                TCBSTATES.style.at(location),
                                TCBSTATES.data.at(location),
                                e.split(splitter).last(),
                                citation-position: "bibliography"))))
            }
        }
    }
}