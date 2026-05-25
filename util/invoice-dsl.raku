grammar Grammar {
    token ws  { \h* }
    token TOP {
        <head-line>
        [ \n+ <.ws> [ <info-line> | <item-line> ] ]*
        \n*
    }
    rule  head-line { invoice  <id>                  }
    rule  info-line { | date   <date>
                          | client <client=quoted>
                          | tax    <tax-rate=number> '%' }
    rule  item-line { item     <description=quoted>
                          hours    <hours=number>
                          rate     <rate=number>         }
    token id        { <[A..Za..z0..9_\-]>+       }
    token date      { \d**4 '-' \d**2 '-' \d**2 }
    token number    { \d+ [ '.' \d+ ]?          }
    token quoted    { '"' <( <-["]>+ )> '"'     }
}

use Actionable; use Form;

class Item does Actionable {
    has ($.description, $.hours, $.rate);
    method subtotal { $.hours * $.rate }
}
class Invoice does Actionable {
    has ($.id, $.date, $.client, $.tax-rate = 0);
    has Item @.items;

    method subtotal { @.items.map(*.subtotal).sum }
    method tax      { $.subtotal * $.tax-rate / 100 }
    method total    { $.subtotal + $.tax }
    method label    { "Tax ($!tax-rate%)" }

    method raku     {
        form( :interleave, q:to/INVOICE/,
            Invoice: {<<<<<}
            Date:    {<<<<<<<<}
            Client:  {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}

            Description                      Hours     Rate   Subtotal
            ----------------------------------------------------------
            {[[[[[[[[[[[[[[[[[[[[[[[[[[[[}  {]]].}  {]]].[}   {]]]].[}
            ----------------------------------------------------------
                                                  {]]]]]]]}   {]]]].[}
            INVOICE

            $.id, $.date, $.client,
            |[@.items.map(*."$_"()) for <description hours rate subtotal>],
            ["Subtotal", $.label, "Total"],
            [$.subtotal, $.tax,  $.total ],
              );
    }
}
class Actions {
    method TOP($/) {
        my $inv = Invoice.action($<head-line>);
        { $inv.action($_) } for $<info-line>;
        { $inv.items.push(Item.action($_)) } for $<item-line>;
        make $inv;
    }
}

my $text = q:to/END/;
invoice INV-001
  date 2026-04-29
  client "Acme Corp"

  item "Website redesign"  hours 10  rate 150
  item "Hosting setup"     hours 2   rate 100

  tax 8%
END

my $match = Grammar.parse($text, actions => Actions.new);
say $match.made;
