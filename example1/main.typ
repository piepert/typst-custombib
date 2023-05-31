#import "../typst-custombib.typ": tcb-bibliography, tcb-cite, tcb-cites, tcb-style, tcb-show-bibliography, ifnotnone, ifhaskey

#tcb-bibliography("example1/bibliography.yaml")
#tcb-style((
    options: (
        is-numerical: false,
        show-sections: true,
        show-bibliography: true,
        title: "Bibliography",
        separator: ", "
    ),

    // how each field is formatted (from entry (source-string) to citation (content))
    fields: (
        // performed on each author name
        author: (entry, author) =>
            smallcaps[#author.last, #author.first#ifhaskey(author, "middle", e => [ #e.middle])],

        // performed on the list of authors
        authors: (entry, authors) =>
            (if authors.len() > 3 {
                (authors.slice(0, 2), [et al]).flatten().join(", ", last: " ")
            } else {
                authors.join(", ", last: " und ")
            }),

        // performed on each prefix and postfix
        postfix: (entry, postfix) => [#ifnotnone(postfix, e => [, #postfix])],
        prefix: (entry, prefix) => [#ifnotnone(prefix, e => [#e ])],

        // fallback
        fallback: (entry, field) => field
    ),

    // for entry-type "custom"
    custom: (
        sort-by: "marker",
        inline: (entry) => [#ifhaskey(entry, "prefix", e => (e.prefix+" "))#eval("["+entry.show-inline+"]")#ifhaskey(entry, "postfix", e => (" "+e.postfix))],
        bibliography: (entry) => [#eval("["+entry.show-bibliography+"]").]
    ),

    inline: (
        fields: (
            // performed on each author name
            author: (entry, author) =>
                smallcaps[#author.first.at(0). #ifhaskey(author, "middle", e => [ #e.middle ]) #author.last]
        ),

        // added after citation
        citation-begin: (entry, citation) => citation,

        // added before citation
        citation-end: (entry, citation) => citation,

        // format single citation inside
        format: (entry, citation) => [#citation],

        // on multiple citations, wrap all of them into this
        wrap-multi: (citations) => [#citations],

        // on all citations cited together tcb-cites / tcb-cite, wrap all of them into this
        wrap-any: (citations) => [#citations],

        types: (
            fallback: (entry, citation) => [#citation.prefix#citation.authors (#citation.year)#citation.postfix]
        )
    ),

    bibliography: (
        format: (entry, citation) => citation,

        types: (
            book: (entry, element) => [#element.authors:
                #emph["#element.title"].
                #ifhaskey(element,
                    "volume",
                    e => [vol. #e.volume.])
                #element.location #element.year.
                #ifhaskey(element,
                    "pages",
                    e => [ S. #if e.pages.ends-with(".") { e.pages } else { e.pages+"." }])],

            fallback: (entry, element) => [#element.authors: #emph["#element.title"].]
        )
    ),

    sections: (
        primary: "Primary Literature",
        secondary: "Secondary Literature"
    )
))

#let ncite(e, postfix: none, prefix: none) = footnote(tcb-cite(e, postfix: postfix, prefix: prefix))

= Title

#lorem(20)

#tcb-cites("Putnam1975", "Hanson2010")

#tcb-cite("Putnam1975", prefix: "vgl.", postfix: "S. 175")

#tcb-cite("Regier2017")

#tcb-cite("KrV", postfix: "A1 / B2")

#tcb-cite("Politeia", postfix: "418e")

#tcb-show-bibliography()