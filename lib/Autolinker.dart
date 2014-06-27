library Autolinker;

class Autolinker {

  bool newWindow = false;
  bool stripPrefix = true;
  bool twitter = false;
  bool email = true;
  bool urls = true;
  String className = "";
  int truncate = null;

  var twitterRegex = '(^|[^\w])@(\w{1,15})',              // For matching a twitter handle. Ex: @gregory_jacobs

    emailRegex = '(?:[\-;:&=\$,\w\.]+@)',             // something@ for email addresses (a.k.a. local-part)

    protocolRegex = '(?:[A-Za-z]{3,9}:(?:\/\/)?)',      // match protocol, allow in format http:// or mailto:
    wwwRegex = '(?:www\.)',                             // starting with 'www.'
    domainNameRegex = '[A-Za-z0-9\.\-]*[A-Za-z0-9\-]',  // anything looking at all like a domain, non-unicode domains, not ending in a period
    tldRegex = '\.(?:international|construction|contractors|enterprises|photography|productions|foundation|immobilien|industries|management|properties|technology|christmas|community|directory|education|equipment|institute|marketing|solutions|vacations|bargains|boutique|builders|catering|cleaning|clothing|computer|democrat|diamonds|graphics|holdings|lighting|partners|plumbing|supplies|training|ventures|academy|careers|company|cruises|domains|exposed|flights|florist|gallery|guitars|holiday|kitchen|neustar|okinawa|recipes|rentals|reviews|shiksha|singles|support|systems|agency|berlin|camera|center|coffee|condos|dating|estate|events|expert|futbol|kaufen|luxury|maison|monash|museum|nagoya|photos|repair|report|social|supply|tattoo|tienda|travel|viajes|villas|vision|voting|voyage|actor|build|cards|cheap|codes|dance|email|glass|house|mango|ninja|parts|photo|shoes|solar|today|tokyo|tools|watch|works|aero|arpa|asia|best|bike|blue|buzz|camp|club|cool|coop|farm|fish|gift|guru|info|jobs|kiwi|kred|land|limo|link|menu|mobi|moda|name|pics|pink|post|qpon|rich|ruhr|sexy|tips|vote|voto|wang|wien|wiki|zone|bar|bid|biz|cab|cat|ceo|com|edu|gov|int|kim|mil|net|onl|org|pro|pub|red|tel|uno|wed|xxx|xyz|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw)\b',
       // match our known top level domains (TLDs)

  // Allow optional path, query string, and hash anchor, not ending in the following characters: "!:,.;"
  // http://blog.codinghorror.com/the-problem-with-urls/
    urlSuffixRegex = '(?:[\-A-Za-z0-9+&@#\/%?=~_()|!:,.;]*[\-A-Za-z0-9+&@#\/%=~_()|])?';  // note: optional part of the full regex

  var tagNameRegex = '[0-9a-zA-Z:]+',
    attrNameRegex = '[^\s\0\"\'>\/=\x01-\x1F\x7F]+',   // the unicode range accounts for excluding control chars, and the delete char
    attrValueRegex = '(?:".*?"|\'.*?\'|[^\'"=<>`\s]+)'; // double quoted, single quoted, or unquoted attribute values

  RegExp matcherRegex;
  RegExp protocolRelativeRegex;
  RegExp htmlRegex;
  RegExp urlPrefixRegex;

  Autolinker({this.twitterRegex:true,this.emailRegex:true}) {
    matcherRegex = new RegExp([
      '(',  // *** Capturing group $1, which can be used to check for a twitter handle match. Use group $3 for the actual twitter handle though. $2 may be used to reconstruct the original string in a replace()
      // *** Capturing group $2, which matches the whitespace character before the '@' sign (needed because of no lookbehinds), and
      // *** Capturing group $3, which matches the actual twitter handle
      twitterRegex,
      ')',

      '|',

      '(',  // *** Capturing group $4, which is used to determine an email match
      emailRegex,
      domainNameRegex,
      tldRegex,
      ')',

      '|',

      '(',  // *** Capturing group $5, which is used to match a URL
      '(?:', // parens to cover match for protocol (optional), and domain
      '(?:',  // non-capturing paren for a protocol-prefixed url (ex: http://google.com)
      protocolRegex,
      domainNameRegex,
      ')',

      '|',

      '(?:',  // non-capturing paren for a 'www.' prefixed url (ex: www.google.com)
      '(.?//)?',  // *** Capturing group $6 for an optional protocol-relative URL. Must be at the beginning of the string or start with a non-word character
      wwwRegex,
      domainNameRegex,
      ')',

      '|',

      '(?:',  // non-capturing paren for known a TLD url (ex: google.com)
      '(.?//)?',  // *** Capturing group $7 for an optional protocol-relative URL. Must be at the beginning of the string or start with a non-word character
      domainNameRegex,
      tldRegex,
      ')',
      ')',

      urlSuffixRegex,  // match for path, query string, and/or hash anchor
      ')'
    ].join(""), caseSensitive: false );

    protocolRelativeRegex = new RegExp('(.)?\/\/');

    htmlRegex = new RegExp( [
      '<(/)?',  // Beginning of a tag. Either '<' for a start tag, or '</' for an end tag. The slash or an empty string is Capturing Group 1.

      // The tag name (Capturing Group 2)
      '(' + tagNameRegex + ')',

      // Zero or more attributes following the tag name
      '(?:',
      '\\s+',  // one or more whitespace chars before an attribute
      attrNameRegex,
      '(?:\\s*=\\s*' + attrValueRegex + ')?',  // optional '=[value]'
      ')*',

      '\\s*',  // any trailing spaces before the closing '>'
      '>'
    ].join( "" ));

    urlPrefixRegex = new RegExp(r'^(https?:\/\/)?(www\.)?', caseSensitive: false);
  }

  String link(String textOrHtml) {
    return processHtml( textOrHtml );
  }

  String processHtml( String html ) {
    // Loop over the HTML string, ignoring HTML tags, and processing the text that lies between them,
    // wrapping the URLs in anchor tags
    var htmlRegex = this.htmlRegex;
    var currentResult,
      inBetweenTagsText,
      lastIndex = 0,
      anchorTagStackCount = 0,
      resultHtml = [];

    var allResults = htmlRegex.allMatches(html);
    allResults.forEach( (Match currentResult) {
      var tagText = currentResult[ 0 ],
        tagName = currentResult[ 2 ],
        isClosingTag = currentResult[ 1 ] != null && currentResult[1].isEmpty;

//      print(currentResult[0]);
//      print(lastIndex);

      inBetweenTagsText = html.substring( lastIndex, currentResult.start );
      lastIndex = currentResult.start + tagText.length;

      // Process around anchor tags, and any inner text / html they may have
      if( tagName == 'a' ) {
        if( !isClosingTag ) {  // it's the start <a> tag
          anchorTagStackCount++;
          resultHtml.add( this.processTextNode( inBetweenTagsText ) );

        } else {   // it's the end </a> tag
          anchorTagStackCount = math.max( anchorTagStackCount - 1, 0 );  // attempt to handle extraneous </a> tags by making sure the stack count never goes below 0
          if( anchorTagStackCount == 0 ) {
            resultHtml.add( inBetweenTagsText );  // We hit the matching </a> tag, simply add all of the text from the start <a> tag to the end </a> tag without linking it
          }
        }

      } else if( anchorTagStackCount == 0 ) {   // not within an anchor tag, link the "in between" text
        resultHtml.add( this.processTextNode( inBetweenTagsText ) );

      } else {
        // if we have a tag that is in between anchor tags (ex: <a href="..."><b>google.com</b></a>),
        // just append the inner text
        resultHtml.add( inBetweenTagsText );
      }

      resultHtml.add( tagText );  // now add the text of the tag itself verbatim
    });

    // Process any remaining text after the last HTML element. Will process all of the text if there were no HTML elements.
    if( lastIndex < html.length ) {
      var processedTextNode = this.processTextNode( html.substring( lastIndex ) );
      resultHtml.add( processedTextNode );
    }

    return resultHtml.join( "" );
  }

  String processTextNode(String text ) {
    var me = this,  // for closures
      matcherRegex = this.matcherRegex,
      enableTwitter = this.twitter,
      enableEmailAddresses = this.email,
      enableUrls = this.urls;

    return text.replaceAllMapped( matcherRegex, (Match m) {
      var matchStr = m[0];
      var twitterMatch = m[1],
        twitterHandlePrefixWhitespaceChar = m[2],  // The whitespace char before the @ sign in a Twitter handle match. This is needed because of no lookbehinds in JS regexes
        twitterHandle = m[3],   // The actual twitterUser (i.e the word after the @ sign in a Twitter handle match)
        emailAddress = m[4],    // For both determining if it is an email address, and stores the actual email address
        urlMatch = m[5],
                // The matched URL string
        protocolRelativeMatch = ((m.groupCount >= 7) && ( m[6] != null ) ) ?  m[6] : ( ((m.groupCount >=8) && (m[7] != null) ) ? m[7] : null ) ,
        //m[6] != null ? m[6] : m[7] != null ? m[7] : null,  // The '//' for a protocol-relative match, with the character that comes before the '//'

        prefixStr = "",       // A string to use to prefix the anchor tag that is created. This is needed for the Twitter handle match
        suffixStr = "";
              // A string to suffix the anchor tag that is created. This is used if there is a trailing parenthesis that should not be auto-linked.

      // Early exits with no replacements for:
      // 1) Disabled link types
      // 2) URL matches which do not have at least have one period ('.') in the domain name (effectively skipping over
      //    matches like "abc:def")
      // 3) A protocol-relative url match (a URL beginning with '//') whose previous character is a word character
      //    (effectively skipping over strings like "abc//google.com")
      if(
          ( twitterMatch != null && !enableTwitter ) || ( emailAddress != null && !enableEmailAddresses ) || ( urlMatch != null && !enableUrls ) ||
          ( urlMatch != null && urlMatch.indexOf( '.' ) == -1 ) ||  // At least one period ('.') must exist in the URL match for us to consider it an actual URL
          ( urlMatch != null && new RegExp('^[A-Za-z]{3,9}:/').hasMatch( urlMatch ) && !new RegExp(':.*?[A-Za-z]').hasMatch( urlMatch ) ) ||  // At least one letter character must exist in the domain name after a protocol match. Ex: skip over something like "git:1.0"
          ( protocolRelativeMatch != null && new RegExp('^[\w]\/\/').hasMatch( protocolRelativeMatch ) )  // a protocol-relative match which has a word character in front of it (so we can skip something like "abc//google.com")
         ) {
        return matchStr;
      }

      // Handle a closing parenthesis at the end of the match, and exclude it if there is not a matching open parenthesis
      // in the match. This handles cases like the string "wikipedia.com/something_(disambiguation)" (which should be auto-
      // linked, and when it is enclosed in parenthesis itself, such as: "(wikipedia.com/something_(disambiguation))" (in
      // which the outer parens should *not* be auto-linked.
      var lastChar = matchStr[( matchStr.length - 1 )];
      if( lastChar == ')' ) {
        var openParensMatch = new RegExp(r'\(').allMatches(matchStr),
          closeParensMatch = new RegExp( r'\)').allMatches(matchStr),
          numOpenParens = ( openParensMatch != null && openParensMatch.length != null ) ? 1 : 0,
          numCloseParens = ( closeParensMatch != null && closeParensMatch.length != null ) ? 1 : 0;

        if( numOpenParens < numCloseParens ) {
          matchStr = matchStr.substring( 0, matchStr.length - 1 );  // remove the trailing ")"
          suffixStr = ")";  // this will be added after the <a> tag
        }
      }


      var anchorHref = matchStr,  // initialize both of these
        anchorText = matchStr,  // values as the full match
        linkType;

      // Process the urls that are found. We need to change URLs like "www.yahoo.com" to "http://www.yahoo.com" (or the browser
      // will try to direct the user to "http://current-domain.com/www.yahoo.com"), and we need to prefix 'mailto:' to email addresses.
      if( twitterMatch != null ) {
        linkType = 'twitter';
        prefixStr = twitterHandlePrefixWhitespaceChar;
        anchorHref = 'https://twitter.com/' + twitterHandle;
        anchorText = '@' + twitterHandle;

      } else if( emailAddress != null ) {
        linkType = 'email';
        anchorHref = 'mailto:' + emailAddress;
        anchorText = emailAddress;

      } else {  // url match
        linkType = 'url';

        if( protocolRelativeMatch != null ) {
          // Strip off any protocol-relative '//' from the anchor text (leaving the previous non-word character
          // intact, if there is one)
          var protocolRelRegex = new RegExp( "^" + me.protocolRelativeRegex ),  // for this one, we want to only match at the beginning of the string
            charBeforeMatch = protocolRelativeMatch.match( protocolRelRegex )[ 1 ] != null ? protocolRelativeMatch.match( protocolRelRegex )[ 1 ] : '';

          prefixStr = charBeforeMatch + prefixStr;  // re-add the character before the '//' to what will be placed before the <a> tag
          anchorHref = anchorHref.replaceFirst( protocolRelRegex, "//" );  // remove the char before the match for the href
          anchorText = anchorText.replaceFirst( protocolRelRegex, "" );    // remove both the char before the match and the '//' for the anchor text

        } else if( !new RegExp('^[A-Za-z]{3,9}:', caseSensitive: false).hasMatch( anchorHref ) ) {
          // url string doesn't begin with a protocol, assume http://
          anchorHref = 'http://' + anchorHref;
        }
      }

      // wrap the match in an anchor tag
      var anchorTag = me.createAnchorTag( linkType, anchorHref, anchorText );
      return prefixStr + anchorTag + suffixStr;
    });
  }

  String createAnchorTag(linkType, anchorHref, anchorText) {
    var attributesStr = this.createAnchorAttrsStr( linkType, anchorHref );
    anchorText = this.processAnchorText( anchorText );

    return '<a ' + attributesStr + '>' + anchorText + '</a>';
  }

  String createAnchorAttrsStr( linkType, anchorHref ) {
    var attrs = [ 'href="' + anchorHref + '"' ];  // we'll always have the `href` attribute

    var cssClass = this.createCssClass( linkType );
    if( !cssClass.isEmpty ) {
      attrs.add( 'class="' + cssClass + '"' );
    }
    if( this.newWindow ) {
      attrs.add( 'target="_blank"' );
    }

    return attrs.join( " " );
  }

  String createCssClass( linkType ) {
    return "";
    // var className = this.className;

    // if( !className.isEmpty )
    //   return "";
    // else
    //   return className + " " + className + "-" + linkType;  // ex: "myLink myLink-url", "myLink myLink-email", or "myLink myLink-twitter"
  }

  String processAnchorText( anchorText ) {
    if( this.stripPrefix ) {
      anchorText = this.stripUrlPrefix( anchorText );
    }
    anchorText = this.removeTrailingSlash( anchorText );  // remove trailing slash, if there is one
    anchorText = this.doTruncate( anchorText );

    return anchorText;
  }

  String stripUrlPrefix( text ) {
    return text.replaceFirst( this.urlPrefixRegex, '' );
  }

  String removeTrailingSlash ( anchorText ) {
    if( anchorText[( anchorText.length - 1 )] == '/' ) {
      anchorText = anchorText.substring( anchorText.length - 2, anchorText.length - 1 );
    }
    return anchorText;
  }

  String doTruncate( anchorText ) {
    var truncateLen = this.truncate;

    // Truncate the anchor text if it is longer than the provided 'truncate' option
    if( truncateLen != null && anchorText.length > truncateLen ) {
      anchorText = anchorText.substring( 0, truncateLen - 2 ) + '..';
    }
    return anchorText;
  }
}