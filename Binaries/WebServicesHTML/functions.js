/* http://www.dustindiaz.com/getelementsbyclass/ */
function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}

function printPagesHTML( numberOfPages, currentPage, parameters)
{
        	if( numberOfPages > 1)
        	{
        		document.write("Pages:  ");
        		
				var i=0;
	            var previous=0;
	            previous = currentPage-1;
	            if( currentPage == 0) document.write("<<  ");
	            else document.write("<b><a href='?"+parameters+"&page="+previous+"'><<  </a></b>");
                
                var start = 1;
                var end = numberOfPages+1;
                
                if( end - start > 10)
                {
                    start = currentPage - 3;
                    end = currentPage + 6;
                }
                
                if( start < 1)
                {
                    end += (-start+1);
                    if( end > numberOfPages+1)
                        end = numberOfPages+1;
                    
                    start = 1;
                }
                
                if( end > numberOfPages+1)
                {
                    start -= end - numberOfPages;
                    if( start < 1)
                        start = 1;
                    
                    end = numberOfPages+1;
                }
                
                if( start == 2)
                    start = 1;
                
                if( end == numberOfPages)
                    end = numberOfPages+1;
                
                if( start != 1)
                {
                    var p = 1;
                    
                    if( 1 == currentPage+1) document.write("<b><u>"+p+"</u></b>  ");
                	else document.write("<a href='?"+parameters+"&page="+0+"'>"+1+"</a>  ");
                    
                    document.write("  ...  ");
                }
                
   	         	for (i=start;i<end;i++)
    	        {
        	    	var page = i-1;
            		if( i == currentPage+1) document.write("<b><u>"+i+"</u></b>  ");
                	else document.write("<a href='?"+parameters+"&page="+page+"'>"+i+"</a>  ");
            	}
                
                if( end != numberOfPages+1)
                {
                    document.write("  ...  ");
                    
                    var p = 0;
                    
                    p = numberOfPages;
                    pp = p-1;
                    
                    if( numberOfPages == currentPage+1) document.write("<b><u>"+p+"</u></b>  ");
                	else document.write("<a href='?"+parameters+"&page="+pp+"'>"+p+"</a>  ");
                }
                
           	 	var next=0;
           	 	next = currentPage+1;
           		if( next >= numberOfPages) document.write("  >>");
            	else document.write("<b><a href='?"+parameters+"&page="+next+"'>  >></a></b>");
            }
}