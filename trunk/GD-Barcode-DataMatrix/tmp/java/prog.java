// Decompiled by DJ v3.9.9.91 Copyright 2005 Atanas Neshkov  Date: 18.01.2007 8:25:29
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   com/idautomation/datamatrix/DataMatrix

import com.idautomation.datamatrix.*;

public class prog
{  
    public static String join(String d, String a[]){
    	String r = "";
    	for (int i=0; i < a.length; i++){
    		r += ( r != "" ? d : "" ) + a[i];
    	}
    	return r;
    }
    public static String join(String d, int a[]){
    	String r = "";
    	for (int i=0; i < a.length; i++){
    		r += ( r != "" ? d : "" ) + a[i];
    	}
    	return r;
    }
    public static String join(String d, short a[]){
    	String r = "";
    	for (int i=0; i < a.length; i++){
    		r += ( r != "" ? d : "" ) + a[i];
    	}
    	return r;
    }
    public static String join(String d, int a[][]){
    	String r = "";
    	for (int i=0; i < a.length; i++){
    		r += ( r != "" ? ", " : "" ) + "[" + a[i][0] + ",.]";
    	}
    	return r;
    }
    public static String dump(int a[][]){
    	String r = "";
    	for (int i=0; i < a.length; i++){
    		r += "[" + join(",",a[i]) + "],\n";
    	}
    	return r;
    }
    public static void main(String args[])
    {
		DataMatrix BC = new DataMatrix();
		//Integer.parseInt(args[0]);
		String text;
		if (args.length > 0) {
			text = args[0];
		}else{
			System.err.println("Usage: prog text [encoding] [format]");
			return;
		}
		
		if (args.length > 1) {
			String arg = args[1].toLowerCase();
			int encoding = -1;
			for (int i=0; i < DataMatrix.encName.length; i++) {
				if (DataMatrix.encName[i].toLowerCase().compareTo( arg ) == 0) {
					encoding = i;
					break;
				}
			}
			if (encoding != -1) {
				// System.out.println(" encoding = " + encoding);
			}else {
				System.err.println("Unknown encoding '" + arg + "'");
				return;
			}
			BC.setEncodingMode(encoding);
		}
		if (args.length > 2) {
			String arg = args[2].toLowerCase();
			int format = -1;
			for (int i=0; i < DataMatrix.formatName.length; i++) {
				if (DataMatrix.formatName[i].toLowerCase().compareTo( arg ) == 0) {
					format = i;
					break;
				}
			}
			if (format != -1) {
				//System.out.println(" encoding = " + encoding);
			}else {
				System.err.println("Unknown format '" + arg + "'");
				return;
			}
			BC.setPreferredFormat(format);
		}
		if (args.length > 3) {
			String arg = args[3].toLowerCase();
			Boolean pt = false;
			if (arg.compareTo("1") == 0) {
				System.out.println("PT = true");
				pt = true;
			}else {
				System.err.println("PT = false");
			}
			BC.setProcessTilde(pt);
		} else {
			System.err.println("PT = false");
			BC.setProcessTilde(false);
		}
		
		//if (true) return;
		/*
    	for (int i=0;i<DataMatrix.C0.length;i++){
			System.out.println("[" + join(", ",DataMatrix.C0[i]) + "],");
		}
		*/
		//BC.setPreferredFormat(14);
		BC.CA(text);
		//BC.CA("241234567890123456789017");
        for(int i1 = 0; i1 < BC.getRows(); i1++)
        {
            for(int j1 = 0; j1 < BC.getCols(); j1++) {
            	System.out.print((BC.bitmap[j1][i1] != 0) ? "*" : " ");
            }
            System.out.println("");
        }
		
    }
}

/*
test:
* * * * * *
* **  **  **
**  * * ***
***    * * *
* **  *   *
**  *      *
**** *
*  * * * * *
*** ** ****
* * *    * *
***  ***  *
************

*/