// Decompiled by DJ v3.9.9.91 Copyright 2005 Atanas Neshkov  Date: 18.01.2007 8:25:29
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   com/idautomation/datamatrix/DataMatrix

package com.idautomation.datamatrix;

import java.awt.*;
import java.awt.image.MemoryImageSource;
import java.awt.image.PixelGrabber;
import java.io.PrintStream;
import java.io.Serializable;
import java.util.Calendar;
import com.idautomation.datamatrix.reed;

// Referenced classes of package com.idautomation.datamatrix:
//            reed, IDAImageCreator


public class DataMatrix extends Canvas
	implements Serializable
{
	private class charPlacer
	{

		private void utah(int i, int j, int k)
		{
			module(i - 2, j - 2, k, 1);
			module(i - 2, j - 1, k, 2);
			module(i - 1, j - 2, k, 3);
			module(i - 1, j - 1, k, 4);
			module(i - 1, j, k, 5);
			module(i, j - 2, k, 6);
			module(i, j - 1, k, 7);
			module(i, j, k, 8);
		}

		private void corner1(int i)
		{
			module(nrow - 1, 0, i, 1);
			module(nrow - 1, 1, i, 2);
			module(nrow - 1, 2, i, 3);
			module(0, ncol - 2, i, 4);
			module(0, ncol - 1, i, 5);
			module(1, ncol - 1, i, 6);
			module(2, ncol - 1, i, 7);
			module(3, ncol - 1, i, 8);
		}

		private void corner2(int i)
		{
			module(nrow - 3, 0, i, 1);
			module(nrow - 2, 0, i, 2);
			module(nrow - 1, 0, i, 3);
			module(0, ncol - 4, i, 4);
			module(0, ncol - 3, i, 5);
			module(0, ncol - 2, i, 6);
			module(0, ncol - 1, i, 7);
			module(1, ncol - 1, i, 8);
		}

		private void corner3(int i)
		{
			module(nrow - 3, 0, i, 1);
			module(nrow - 2, 0, i, 2);
			module(nrow - 1, 0, i, 3);
			module(0, ncol - 2, i, 4);
			module(0, ncol - 1, i, 5);
			module(1, ncol - 1, i, 6);
			module(2, ncol - 1, i, 7);
			module(3, ncol - 1, i, 8);
		}

		private void corner4(int i)
		{
			module(nrow - 1, 0, i, 1);
			module(nrow - 1, ncol - 1, i, 2);
			module(0, ncol - 3, i, 3);
			module(0, ncol - 2, i, 4);
			module(0, ncol - 1, i, 5);
			module(1, ncol - 3, i, 6);
			module(1, ncol - 2, i, 7);
			module(1, ncol - 1, i, 8);
		}

		public void make()
		{
			int i = 1;
			int j = 4;
			int k = 0;
			for(int l = 0; l < nrow; l++)
			{
				for(int i1 = 0; i1 < ncol; i1++)
					array[l * ncol + i1] = 0;

			}

			do
			{
				if(j == nrow && k == 0)
					corner1(i++);
				if(j == nrow - 2 && k == 0 && ncol % 4 != 0)
					corner2(i++);
				if(j == nrow - 2 && k == 0 && ncol % 8 == 4)
					corner3(i++);
				if(j == nrow + 4 && k == 2 && ncol % 8 == 0)
					corner4(i++);
				do
				{
					if(j < nrow && k >= 0 && array[j * ncol + k] == 0)
						utah(j, k, i++);
					j -= 2;
					k += 2;
				} while(j >= 0 && k < ncol);
				j++;
				k += 3;
				do
				{
					if(j >= 0 && k < ncol && array[j * ncol + k] == 0)
						utah(j, k, i++);
					j += 2;
					k -= 2;
				} while(j < nrow && k >= 0);
				j += 3;
				k++;
			} while(j < nrow || k < ncol);
			if(array[nrow * ncol - 1] == 0)
				array[nrow * ncol - 1] = array[nrow * ncol - ncol - 2] = 1;
		}

		private void module(int i, int j, int k, int l)
		{
			if(i < 0)
			{
				i += nrow;
				j += 4 - (nrow + 4) % 8;
			}
			if(j < 0)
			{
				j += ncol;
				i += 4 - (ncol + 4) % 8;
			}
			array[i * ncol + j] = 10 * k + l;
		}

		public int nrow;
		public int ncol;
		public int array[];

		private charPlacer()
		{
		}

	}


	public DataMatrix()
	{
		code = "NO DATA";
		marginCM = 0.059999999999999998D;
		leftMarginPixels = 0;
		topMarginPixels = 0;
		endOfCode = 0;
		backColor = Color.white;
		codeText = "";
		narrowBarPixels = 0;
		widthBarPixels = 0;
		narrowBarCM = 0.0D;
		widthBarCM = 0.0D;
		resolution = 38;
		barHeightPixels = 0;
		N = 2D;
		X = 0.059999999999999998D;
		width = 140;
		height = 140;
		pWidth = width;
		pHeight = height;
		autoSize = true;
		textFont = new Font("Arial", 0, 11);
		fontColor = Color.black;
		barColor = Color.black;
		I = 1.0D;
		H = 0.45000000000000001D;
		L = 0.0D;
		rotate = 0;
		currentX = 0;
		currentY = 0;
		extraHeight = 0;
		dotPixels = 0;
		margin = 0;
		processTilde = false;
		encoding = E_ASCII;
		reBuild = true;
		internalCode = "";
		preferredFormat = -1;
		currentEncoding = E_ASCII;
		C49rest = 0;
	}
	public static String join(String d, String a[]){
		String r = "";
		for (int i=0; i < a.length; i++){
			r += ( r != "" ? d : "" ) + a[i];
		}
		return r;
	}
	public static String join(String d, int a[]){
		String r = "";
		String rs = "";
		for (int i=0; i < a.length; i++){
			if (a[i] == 0) {
				rs += ( r != "" ? d : "" ) + a[i];
			} else {
				if (rs != "") {
					r += ( r != "" ? d : "" ) + rs;
					rs = "";
				}
				r += ( r != "" ? d : "" ) + a[i];
			}
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

	public void setDataToEncode(String s)
	{
		code = s;
		reBuild = true;
		invalidate();
	}

	public String getDataToEncode()
	{
		return code;
	}

	public void setMarginCM(double d)
	{
		marginCM = d;
		reBuild = true;
		invalidate();
	}

	public double getMarginCM()
	{
		return marginCM;
	}

	public void setBackground(Color color)
	{
		backColor = color;
		invalidate();
	}

	public Color getBackground()
	{
		return backColor;
	}

	public void setPixelsPerCM(int i)
	{
		resolution = i;
		invalidate();
	}

	public int getPixelsPerCM()
	{
		return resolution;
	}

	public void setXDimensionCM(double d)
	{
		X = d;
		reBuild = true;
		invalidate();
	}

	public double getXDimensionCM()
	{
		return X;
	}

	public void setAutoSize(boolean flag)
	{
		autoSize = flag;
		invalidate();
	}

	public boolean getAutoSize()
	{
		return autoSize;
	}

	public Dimension getPreferredSize()
	{
		return new Dimension(pWidth, pHeight);
	}

	public Dimension getMinimumSize()
	{
		Dimension dimension = new Dimension(8, 8);
		return dimension;
	}

	public void setForeground(Color color)
	{
		barColor = color;
		invalidate();
	}

	public Color getForeground()
	{
		return barColor;
	}

	public void setRotationAngle(int i)
	{
		rotate = i;
		invalidate();
	}

	public int getRotationAngle()
	{
		return rotate;
	}

	public void setProcessTilde(boolean flag)
	{
		processTilde = flag;
		reBuild = true;
		invalidate();
	}

	public boolean getProcessTilde()
	{
		return processTilde;
	}

	public void setEncodingMode(int i)
	{
		encoding = i;
		reBuild = true;
		invalidate();
	}

	public int getEncodingMode()
	{
		return encoding;
	}

	public void setPreferredFormat(int i)
	{
		preferredFormat = i;
		reBuild = true;
		invalidate();
	}

	public int getPreferredFormat()
	{
		return preferredFormat;
	}
	
	public int getCols() {
		return cols;
	}

	public int getRows() {
		return rows;
	}

	private int C0(int i, int j)
	{
		int k = (149 * j) % 255 + 1;
		int l = i + k;
		if(l <= 255)
			return l;
		else
			return l - 256;
	}

	private boolean C1(int i)
	{
		return i >= 48 && i <= 57;
	}

	private void C2(int ai[], int ai1[], int i, int j, int k)
	{
		for(int l = 0; l < k; l++)
			ai1[j + l] = ai[i + l];

	}
	private void C2(String ai[], String ai1[], int i, int j, int k)
	{
		for(int l = 0; l < k; l++)
			ai1[j + l] = ai[i + l];

	}

	private int C3(int ai[], int i, int j, String as[])
	{
		//System.out.println("C3( *** )");
		double d = 0.0D;
		double d2 = 1.0D;
		double d3 = 1.0D;
		double d4 = 1.25D;
		int k = j;
		if(i != E_ASCII)
		{
			d = 1.0D;
			d2 = 2D;
			d3 = 2D;
			d4 = 2.25D;
		}
		if(i == E_C40)
			d2 = 0.0D;
		if(i == E_TEXT)
			d3 = 0.0D;
		if(i == E_BASE256)
			d4 = 0.0D;
		for(; j < ai.length; j++)
		{
			char c = (char)ai[j];
			if(C1(c))
				d += 0.5D;
			else
			if(c > '\177')
				d = Math.round(d) + 2L;
			else
				d = Math.round(d) + 1L;
			if(C1[c].length == 1)
				d2 += 0.66000000000000003D;
			else
			if(c > '\177')
				d2 += 2.6600000000000001D;
			else
				d2 += 1.3300000000000001D;
			char c1 = c;
			String s = "" + c;
			if(c >= 'A' && c <= 'Z')
				c1 = s.toLowerCase().charAt(0);
			if(c >= 'a' && c <= 'z')
				c1 = s.toUpperCase().charAt(0);
			if(C1[c1].length == 1)
				d3 += 0.66000000000000003D;
			else
			if(c1 > '\177')
				d3 += 2.6600000000000001D;
			else
				d3 += 1.3300000000000001D;
			d4++;
			if(as[j] != null)
				return E_ASCII;
			if(j - k >= 4)
			{
				if (DEBUGEAUTO) System.out.println(""+j+"-"+k+" >= 4: "+d+" "+d2+" "+d3+" "+d4);
				if(d + 1.0D <= d2 && d + 1.0D <= d3 && d + 1.0D <= d4)
					return E_ASCII;
				if(d4 + 1.0D <= d)
					return E_BASE256;
				if(d4 + 1.0D < d3 && d4 + 1.0D < d2)
					return E_BASE256;
				if(d3 + 1.0D < d && d3 + 1.0D < d2 && d3 + 1.0D < d4)
					return E_TEXT;
				if(d2 + 1.0D < d && d2 + 1.0D < d3 && d2 + 1.0D < d4)
					return E_C40;
			}
		}

		d = Math.round(d);
		d2 = Math.round(d2);
		d3 = Math.round(d3);
		d4 = Math.round(d4);
		if(d <= d2 && d <= d3 && d <= d4)
			return E_ASCII;
		if(d3 < d && d3 < d2 && d3 < d4)
			return E_TEXT;
		if(d4 < d && d4 < d3 && d4 < d2)
			return E_BASE256;
		else
			return E_C40;
	}

	private int C4(int i, int ai[], int ai1[], String as[])
	{
		//System.out.println("C4( *** )");
		int ai2[] = new int[6000];
		int ai3[] = new int[6000];
		boolean flag = false;
		int j1 = 0;
		int k1 = E_ASCII;
		int ai4[] = new int[1];
		int ai5[] = new int[1];
		int l2 = E_ASCII;
		String as1[] = new String[10];
		for(int i3 = 0; i3 < as1.length; i3++)
			as1[i3] = null;

		int j3 = 0;
		currentEncoding = E_ASCII;
		if (DEBUGEAUTO) System.out.println("DetectENC: starting from "+encName[currentEncoding]);
		while(j3 < i) 
		{
			if (DEBUGEAUTO) System.out.println("DetectENC: at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
			while(currentEncoding == E_ASCII && j3 < i) 
			{
				if (DEBUGEAUTO) System.out.println("DetectENC: while at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
				boolean flag1 = false;
				if(j3 + 1 < i && C1(ai[j3]) && C1(ai[j3 + 1]))
				{
					if (DEBUGEAUTO) System.out.println("DetectENC: 2 dig "+ai[j3]+"+"+ai[j3+1]+" at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
					if(l2 != E_ASCII)
						ai1[j1++] = 254;
					ai2[0] = ai[j3];
					ai2[1] = ai[j3 + 1];
					int j = CE(2, ai2, ai3, as1);
					C2(ai3, ai1, 0, j1, j);
					j1 += j;
					j3++;
					j3++;
					flag1 = true;
					l2 = E_ASCII;
				}
				if(!flag1)
				{
					if (DEBUGEAUTO) System.out.println("DetectENC: !dig !flag1 at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
					int l1 = C3(ai, currentEncoding, j3, as);
					if(l1 != E_ASCII)
					{
						if (DEBUGEAUTO) System.out.println("DetectENC: "+encName[currentEncoding]+" => "+encName[l1]);
						l2 = currentEncoding;
						currentEncoding = l1;
					}
				}
				if(!flag1 && currentEncoding == E_ASCII)
				{
					if(l2 != E_ASCII)
						ai1[j1++] = 254;
					ai2[0] = ai[j3];
					as1[0] = as[j3];
					int k = CE(1, ai2, ai3, as1);
					as1[0] = null;
					C2(ai3, ai1, 0, j1, k);
					j1 += k;
					j3++;
					l2 = E_ASCII;
				}
			}
			if (DEBUGEAUTO) System.out.println("DetectENC: after while at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
			int i2;
			for(; currentEncoding == E_C40 && j3 < i; currentEncoding = i2)
			{
				ai4[0] = j3;
				int l = C6(i, ai4, ai, ai3, false, l2 != E_C40, true);
				j3 = ai4[0];
				C2(ai3, ai1, 0, j1, l);
				j1 += l;
				i2 = C3(ai, currentEncoding, j3, as);
				l2 = currentEncoding;
			}
			if (DEBUGEAUTO) System.out.println("DetectENC: after C40 at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);

			int j2;
			for(; currentEncoding == E_TEXT && j3 < i; currentEncoding = j2)
			{
				ai4[0] = j3;
				int i1 = C6(i, ai4, ai, ai3, true, l2 != E_TEXT, true);
				j3 = ai4[0];
				C2(ai3, ai1, 0, j1, i1);
				j1 += i1;
				j2 = C3(ai, currentEncoding, j3, as);
				l2 = currentEncoding;
			}
			if (DEBUGEAUTO) System.out.println("DetectENC: after TEXT at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);

			if(currentEncoding == E_BASE256)
			{
				ai4[0] = j3;
				ai5[0] = j1;
				C5(i, ai4, ai, ai5, ai1, true, as);
				j3 = ai4[0];
				j1 = ai5[0];
				int k2 = C3(ai, currentEncoding, j3, as);
				l2 = currentEncoding;
				currentEncoding = k2;
			}
			if (DEBUGEAUTO) System.out.println("DetectENC: after B256 at "+j3+" ce="+encName[currentEncoding]+" k1="+encName[k1]+" l2="+encName[l2]);
		}
		return j1;
	}

	private int C5(int i, int ai[], int ai1[], int ai2[], int ai3[], boolean flag, String as[])
	{
		//System.out.println("C5( *** )");
		int j = 0;
		int ai4[] = new int[6000];
		int k = ai2[0];
		int l = ai2[0];
		boolean flag1 = false;
		int j1 = 0;
		for(j1 = ai[0]; j1 < i; j1++)
		{
			ai4[j] = ai1[j1];
			j++;
			int i1 = j1 + 1;
			if(flag && C3(ai1, E_BASE256, i1, as) != E_BASE256)
				break;
		}

		ai[0] = j1;
		ai3[l++] = 231;
		if(j < 250)
		{
			ai3[l] = C0(j, l + 1);
			l++;
		} else
		{
			ai3[l] = C0(249 + (i - i % 250) / 250, l + 1);
			l++;
			ai3[l] = C0(i % 250, l + 1);
			l++;
		}
		for(int k1 = 0; k1 < j; k1++)
		{
			ai3[l] = C0(ai4[k1], l + 1);
			l++;
		}

		ai2[0] = l;
		return l;
	}

	private int C6(int i, int ai[], int ai1[], int ai2[], boolean flag, boolean flag1, boolean flag2)
	{
		//System.out.println("C6( *** )");
		int j = 0;
		int k = 0;
		int ai3[] = {
			0, 0, 0
		};
		boolean flag3 = false;
		String as[] = new String[10];
		for(int i1 = 0; i1 < as.length; i1++)
			as[i1] = null;

		if(flag1)
			if(flag)
				ai2[j++] = 239;
			else
				ai2[j++] = 230;
		for(int j1 = ai[0]; j1 < i; j1++)
		{
			int l = ai1[j1];
			if(flag)
			{
				String s = "" + (char)l;
				if(l >= 97 && l <= 122)
					s = s.toUpperCase();
				if(l >= 65 && l <= 90)
					s = s.toLowerCase();
				l = s.charAt(0);
			}
			int ai4[] = C1[l];
			for(int l1 = 0; l1 < ai4.length; l1++)
			{
				ai3[k++] = ai4[l1];
				if(k == 3)
				{
					int i2 = ai3[0] * 1600 + ai3[1] * 40 + ai3[2] + 1;
					ai2[j++] = i2 / 256;
					ai2[j++] = i2 % 256;
					k = 0;
				}
			}

			if(flag2 && k == 0)
			{
				C49rest = k;
				ai[0] = j1 + 1;
				if(ai[0] == i)
					ai2[j++] = 254;
				return j;
			}
		}

		ai[0] = i;
		if(k > 0)
		{
			if(k == 1)
			{
				ai2[j++] = 254;
				ai2[j++] = ai1[i - 1] + 1;
				return j;
			}
			if(k == 2)
			{
				ai3[2] = 0;
				int k1 = ai3[0] * 1600 + ai3[1] * 40 + ai3[2] + 1;
				ai2[j++] = k1 / 256;
				ai2[j++] = k1 % 256;
				ai2[j++] = 254;
				C49rest = k;
				return j;
			}
		} else
		{
			ai2[j++] = 254;
		}
		C49rest = k;
		return j;
	}

	protected void paintBasis(Graphics g) { }

	private int C8(int i, int j)
	{
		int k = (149 * j) % 253 + 1;
		int l = i + k;
		if(l <= 254)
			return l;
		else
			return l - 254;
	}

	private String C9(String s, String as[])
	{
		boolean flag = false;
		int k = s.length();
		String s1 = "";
		boolean flag1 = false;
		for(int i = 0; i < k; i++)
		{
			int j = s.charAt(i);
			if(j == 126)
			{
				if(i < k - 1)
				{
					char c = s.charAt(i + 1);
					if(c >= '@' && c <= 'Z')
					{
						i++;
						s1 = s1 + (char)(c - 64);
					}
					if(c == '~')
					{
						s1 = s1 + '~';
						i++;
					}
					if(c == '1')
					{
						if(s1.length() == 0 || s1.length() == 1 || s1.length() == 4 || s1.length() == 5)
						{
							if (DEBUG) System.out.println("PT affect as["+s1.length()+"] = ''");
							as[s1.length()] = "";
							s1 = s1 + '\350';
						} else
						{
							s1 = s1 + '\035';
						}
						i++;
					}
					if(c == '2' && i < k - 4)
					{
						if (DEBUG) System.out.println("PT affect as["+s1.length()+"] += '"+s.charAt(i + 2) + s.charAt(i + 3) + s.charAt(i + 4)+"'");
						as[s1.length()] = "" + s.charAt(i + 2) + s.charAt(i + 3) + s.charAt(i + 4);
						s1 = s1 + '\351';
						i += 4;
					}
					if(c == '3' && s1.length() == 0)
					{
						if (DEBUG) System.out.println("PT affect as["+s1.length()+"] = ''");
						as[s1.length()] = "";
						s1 = s1 + '\352';
						i++;
					}
					if(c == '5' && s1.length() == 0)
					{
						as[s1.length()] = "";
						s1 = s1 + '\354';
						i++;
					}
					if(c == '6' && s1.length() == 0)
					{
						as[s1.length()] = "";
						s1 = s1 + '\355';
						i++;
					}
					if(c == '7' && i < k - 7)
					{
						String s2 = s.substring(i + 2, i + 8);
						double d = 0.0D;
						try
						{
							d = (new Double(s2)).doubleValue();
						}
						catch(Exception exception1)
						{
							d = 0.0D;
						}
						if (DEBUG) System.out.println("There is "+d+" got from " + s2);
						if(d <= 126D)
						{
							as[s1.length()] = "" + (char)(int)(d + 1.0D);
							if (DEBUG) System.out.println("PT affect as["+s1.length()+"] = '"+ (int)(d + 1.0D) +"'");
							s1 = s1 + '\361';
						}
						if(d >= 127D && d <= 16382D)
						{
							int i1 = (int)((d - 127D) / 254D) + 128;
							int k1 = (int)((d - 127D) % 254D) + 1;
							if (DEBUG) System.out.println("PT affect as["+s1.length()+"] = '"+ i1 +"+"+ k1+ "'");
							as[s1.length()] = "" + (char)i1 + (char)k1;
							s1 = s1 + '\361';
						}
						if(d >= 16383D)
						{
							int j1 = (int)((d - 16383D) / 64516D) + 192;
							int l1 = (int)((d - 16383D) / 254D);
							l1 = l1 % 254 + 1;
							int i2 = (int)((d - 16383D) % 254D) + 1;
							if (DEBUG) System.out.println("PT affect as["+s1.length()+"] = '"+j1 +"+"+ l1 +"+" + i2+"'");
							as[s1.length()] = "" + (char)j1 + (char)l1 + (char)i2;
							s1 = s1 + '\361';
						}
						i += 7;
					}
					if(c == 'd' && i < k - 3)
					{
						String s3 = s.substring(i + 2, i + 5);
						int l = 0;
						try
						{
							l = (new Integer(s3)).intValue();
						}
						catch(Exception exception)
						{
							l = 0;
						}
						if(l > 255)
							l = 255;
						s1 = s1 + (char)l;
						i += 4;
					}
				}
			} else
			{
				s1 = s1 + (char)j;
			}
		}

		if (DEBUG) System.out.println("ProcessTilde(s["+s+"],as["+as.length+"] => s1["+s1+"])");
		return s1;
	}

	public void CA(String text)
	{
		if (DEBUG) System.out.println("text("+text+")");
		String as[] = new String[5000];
		reBuild = false;
		internalCode = code = text;
		if(processTilde)
			internalCode = C9(code, as);
		if(internalCode.length() == 0)
			return;
		//System.out.println("text("+internalCode+")");
		int ai[] = new int[internalCode.length()];
		for(int i = 0; i < internalCode.length(); i++)
			ai[i] = internalCode.charAt(i);

		bitmap = CB(ai, as);
	}

	private int[][] CB(int ai[], String as[])
	{
		String tmp[] = new String[5];
		C2(as,tmp,0,0,5);
		if (DEBUG) System.out.println("[CB] CreateBitmap(ai["+join(",",ai)+"]");
		int ai1[] = new int[5000];
		int ai2[] = new int[1];
		int ai3[] = new int[1];
		int i = 0;
		if(encoding != E_AUTO)
			currentEncoding = encoding;
		if(encoding == E_AUTO)
			i = C4(ai.length, ai, ai1, as);
		if(encoding == E_ASCII)
			i = CE(ai.length, ai, ai1, as);
		if(encoding == E_C40)
			i = C6(ai.length, ai2, ai, ai1, false, true, false);
		if(encoding == E_TEXT)
			i = C6(ai.length, ai2, ai, ai1, true, true, false);
		if(encoding == E_BASE256)
			i = C5(ai.length, ai2, ai, ai3, ai1, false, as);
		if(encoding == E_NONE)
		{
			i = ai.length;
			for(int j = 0; j < i; j++)
				ai1[j] = ai[j];

		}
		if (DEBUG) System.out.println("[CB] selected (ai1["+join(",",ai1)+"]");
		//System.out.println("[CB]: enc: " + encName[encoding] + "; " + encName[currentEncoding]);
		if (MDEBUG) System.out.println("Use Encoding: " + encName[currentEncoding] + "(" + encName[encoding] + ")");
		int k = 0;
		if(preferredFormat != -1)
		{
			k = preferredFormat;
			if(i > C0[k][7])
				k = 0;
		}
		//System.out.println("[CB]: format: " + k);
		for(; i > C0[k][7] && k < 30; k++)
		{
			if(currentEncoding != E_C40 && currentEncoding != E_TEXT)
				continue;
			//System.out.println("[CB]: enc: E_C40 || E_TEXT");
			if(C49rest == 1 && ai1[i - 2] == 254 && C0[k][7] == i - 1)
			{
				ai1[i - 2] = ai1[i - 1];
				ai1[i - 1] = 0;
				i--;
				break;
			}
			if(C49rest != 0 || ai1[i - 1] != 254 || C0[k][7] != i - 1)
				continue;
			ai1[i - 1] = 0;
			i--;
			break;
		}
		if(k == 30)
			return null;
		int l = k;
		rows = C0[l][0];
		cols = C0[l][1];
		datarows = C0[l][2];
		datacols = C0[l][3];
		regions = C0[l][4];
		maprows = C0[l][5];
		mapcols = C0[l][6];
		totaldata = C0[l][7];
		totalerr = C0[l][8];
		reeddata = C0[l][9];
		reederr = C0[l][10];
		reedblocks = C0[l][11];
		//System.out.println("[CB]: Selected "+rows+"x"+cols+" ["+totaldata+"]; " + i);
		if (MDEBUG) System.out.println("Format: "+rows+"x"+cols+"; Data: "+totaldata+"; i=" + i + "; blocks = "+reedblocks);
		if((currentEncoding == E_C40 || currentEncoding == E_TEXT) && C49rest == 0 && i == totaldata && ai1[i - 1] == 254)
			ai1[i - 1] = 129;
		int ai4[][] = new int[10][255];
		boolean flag = true;
		for(int i1 = i; i1 < totaldata; i1++)
		{
			if(flag)
				ai1[i1] = 129;
			else
				ai1[i1] = C8(129, i1 + 1);
			flag = false;
		}
		if (DEBUG) System.out.println("[CB]: ai1:{ "+join(",",ai1) + " }");
		

		int j1 = 0;
		int k1 = 0;
		for(int l1 = 1; l1 <= totaldata; l1++)
		{
			ai4[j1][k1] = ai1[l1 - 1];
			if(++j1 == reedblocks)
			{
				j1 = 0;
				k1++;
			}
		}

		int ai5[] = new int[10];
		int i2 = 0;
		reed reed1 = new reed();
		reed.K = reeddata;
		for(int j2 = 0; j2 < reedblocks; j2++)
		{
			ai5[j2] = reeddata + reederr;
			int k2 = reeddata;
			if(rows == 144 && j2 > 7)
			{
				ai5[j2] = (reeddata + reederr) - 1;
				k2 = 155;
			}
		if (DEBUG) System.out.println("[CB] ("+k2+", "+ reederr +") ai4["+j2+"]:{ "+join(",",ai4[j2]) + " }");
		//System.out.println("[CB]: calc " + k2 + ", " + reederr);
			reed1.calcRS(ai4[j2], k2, reederr);
		//System.out.println("[CB]: ai4["+j2+"]:{ "+join(",",ai4[j2]) + " }");
			i2 += ai5[j2];
		}
		//System.out.println("[CB]: ai5:{ "+join(",",ai5) + " }");
		int ai6[] = new int[i2];
		int l2 = 0;
		int i3 = 0;
		for(int j3 = 0; j3 < ai5[0]; j3++)
		{
			for(int k3 = 0; k3 < reedblocks; k3++){ 
				//System.out.println("[CB]: " + j3 + ":" + k3 + " => " + ( j3 < ai5[k3] ? "+" : "-" ) );
				if(j3 < ai5[k3])
				{
					ai6[i3++] = ai4[k3][j3];
					l2++;
				}
			}
		}

		int ai7[][] = CC(ai6);
		return ai7;
	}

	private int[][] CC(int ai[])
	{
		if (DEBUG) System.out.println("[CC] GenData: "+join(",",ai)+" ["+cols+"x"+rows+" : "+regions+"]");
		int ai1[][] = new int[cols][rows];
		int i = 0;
		int j = 0;
		if(regions == 2)
		{
			CD(ai1, i, j, datacols + 2, datarows + 2);
			CD(ai1, i + datacols + 2, j, datacols + 2, datarows + 2);
		} else
		{
			int k = (int)Math.sqrt(regions);
			for(int l = 0; l < k; l++)
			{
				for(int i1 = 0; i1 < k; i1++)
					CD(ai1, i + l * (datacols + 2), j + i1 * (datarows + 2), datacols + 2, datarows + 2);

			}

		}
		int ai2[] = new int[(mapcols + 10) * maprows];
		//System.out.println("AI2{" + join(" ",ai2) +"}");
		charPlacer charplacer = new charPlacer();
		charplacer.ncol = mapcols;
		charplacer.nrow = maprows;
		charplacer.array = ai2;
		charplacer.make();
		//System.out.println("AI2{" + join(" ",ai2) +"}");
		//System.out.println("-----------");
		//System.out.println("AI{" + join(" ",ai) +"}");
		//for (int x=0;x< ai2.length;x++){
		//	System.out.println("" + ai2[x] +",");
		//}
		int j1 = 1;
		boolean flag = false;
		boolean flag1 = false;
		for(int i2 = 0; i2 < maprows; i2++)
		{
			int j2 = 1;
			for(int k2 = 0; k2 < mapcols; k2++)
			{
				int l1 = k2 + j2;
				int k1 = i2 + j1;
				if(ai2[i2 * mapcols + k2] > 9)
				{
					int l2 = ai2[i2 * mapcols + k2] / 10;
					int i3 = ai2[i2 * mapcols + k2] % 10;
					int j3 = ai[l2 - 1] & 1 << 8 - i3;
					ai1[l1][k1] = j3;
					if (l1 > 27 && l1 < 32 && k1 >=0 && k1 < 5){
						//System.out.println("" + l1+" x "+k1+" => " + j3 + " ai["+l2+" - 1]( "+ai[l2 - 1]+" & 1 << 8 - " + i3 + " )");
					}
				} else
				{
					ai1[l1][k1] = ai2[i2 * mapcols + k2];
				}
				if(k2 > 0 && (k2 + 1) % datacols == 0)
					j2 += 2;
			}

			if(i2 > 0 && (i2 + 1) % datarows == 0)
				j1 += 2;
		}
		double base = Math.log(2);
		for (int x=0;x< ai1.length;x++){
			for (int y=0;y< ai1[x].length;y++){
				if (ai1[x][y] > 0){
					//System.out.print((int)Math.floor(Math.log(ai1[x][y])/base));
				}else{
					//System.out.print(" ");
				}
			}
			//System.out.println("");
		}
		return ai1;
	}

	private void CD(int ai[][], int i, int j, int k, int l)
	{
		//System.out.println("CD(ai["+join(",",ai)+"],"+i+","+j+","+k+","+l+")");
		int i1 = 0;
		for(int k1 = 0; k1 < k; k1++)
		{
			if(k1 % 2 == 0)
				i1 = 1;
			else
				i1 = 0;
			ai[i + k1][(j + l) - 1] = 1;
			ai[i + k1][j] = i1;
		}

		i1 = 0;
		for(int l1 = 0; l1 < l; l1++)
		{
			int j1;
			if((l1 + 1) % 2 == 0)
				j1 = 1;
			else
				j1 = 0;
			ai[i][j + l1] = 1;
			ai[(i + k) - 1][j + l1] = j1;
		}

	}

	private int CE(int i, int ai[], int ai1[], String as[])
	{
		if (DEBUG) System.out.println("[CE] DetectASCII()");
		if (DEBUG) System.out.println("[CE] ai:{"+join(" ",ai)+"}");
		int j = 0;
		boolean flag = false;
		for(int k = 0; k < i; k++)
		{
			boolean flag1 = false;
			if(k < i - 1 && ai[k] >= 48 && ai[k] <= 57 && ai[k + 1] >= 48 && ai[k + 1] <= 57 && k < i)
			{
				if (DEBUG) System.out.println("[CE] "+flag+"/"+flag1+" "+k+" "+ai[k]+" is type 1");
				int l = (ai[k] - 48) * 10 + (ai[k + 1] - 48);
				ai1[j++] = 130 + l;
				k++;
				flag1 = true;
			}
			if(!flag1 && as[k] != null)
			{
				if (DEBUG) System.out.println("[CE] "+flag+"/"+flag1+" "+k+" "+ai[k]+" is subtype");
				if(ai[k] == 234 || ai[k] == 237 || ai[k] == 236 || ai[k] == 232)
				{
					if (DEBUG) System.out.println("[CE] "+flag+"/"+flag1+" "+k+" "+ai[k]+" is type 2");
					ai1[j++] = ai[k];
					flag1 = true;
				}
				if(ai[k] == 233 || ai[k] == 241)
				{
					ai1[j++] = ai[k];
					if (DEBUG) System.out.println("Additional data by 233/241 for "+k+": "+as[k]+"");
					for(int i1 = 0; i1 < as[k].length(); i1++)
						ai1[j++] = as[k].charAt(i1);

					flag1 = true;
				}
			}
			if(!flag1)
				if(ai[k] < 128)
				{
					if (DEBUG) System.out.println("[CE] "+flag+"/"+flag1+" "+k+" "+ai[k]+" is type 3");
					ai1[j++] = ai[k] + 1;
				} else
				{
					if (DEBUG) System.out.println("[CE] "+flag+"/"+flag1+" "+k+" "+ai[k]+" is type 4");
					ai1[j++] = 235;
					ai1[j++] = (ai[k] - 128) + 1;
				}
		}

		if (DEBUG) System.out.println("[CE] end "+j+" ai1:{"+join(" ",ai1)+"};");
		return j;
	}

	protected void addBar(Graphics g, int i, boolean flag, int j)
	{
		if(flag)
		{
			g.setColor(barColor);
			g.fillRect(currentX, topMarginPixels + j, i, (barHeightPixels + extraHeight) - j);
		}
		currentX = currentX + i;
	}

	protected void paintChar(Graphics g, String s, String s1)
	{
		paintChar2(g, s, s1, 0);
	}

	protected void paintChar2(Graphics g, String s, String s1, int i)
	{
		for(int j = 0; j < s.length(); j++)
		{
			char c = s.charAt(j);
			char c1 = s1.charAt(j);
			if(c1 == 'n')
				addBar(g, narrowBarPixels, c == 'b', i);
			if(c1 == 'w')
				addBar(g, widthBarPixels, c == 'b', i);
			if(c1 == '1')
				addBar(g, narrowBarPixels, c == 'b', i);
			if(c1 == '2')
				addBar(g, narrowBarPixels * 2, c == 'b', i);
			if(c1 == '3')
				addBar(g, narrowBarPixels * 3, c == 'b', i);
			if(c1 == '4')
				addBar(g, narrowBarPixels * 4, c == 'b', i);
		}

	}

	protected void calculateSizes()
	{
		int i = code.length();
		narrowBarCM = X;
		widthBarCM = X * N;
		if(narrowBarCM != 0.0D)
			narrowBarPixels = (int)(narrowBarCM * (double)resolution);
		if(widthBarCM != 0.0D)
			widthBarPixels = (int)(widthBarCM * (double)resolution);
		if(narrowBarPixels <= 0)
			narrowBarPixels = 1;
	}

	public void paint(Graphics g)
	{
		Graphics g1 = g;
		Image image = null;
		if(rotate != 0)
		{
			String s = System.getProperty("java.version");
			if(s.indexOf("1.0") == 0 || s.indexOf("1.1") == 0)
			{
				image = createImage(getSize().width, getSize().height);
				g1 = image.getGraphics();
			} else
			{
				IDAImageCreator idaimagecreator = new IDAImageCreator();
				image = idaimagecreator.getImage(getSize().width, getSize().height);
				g1 = idaimagecreator.getGraphics();
			}
		}
		g.setColor(backColor);
		g.fillRect(0, 0, getSize().width, getSize().height);
		paintBasis(g1);
		if(rotate != 0)
		{
			int i = currentX + leftMarginPixels;
			int j = currentY + topMarginPixels;
			Image image1 = rotate(image, rotate, i, j);
			if(image1 == null)
				g.drawImage(image, 0, 0, null);
			else
				g.drawImage(image1, 0, 0, null);
		}
	}

	protected Image rotate(Image image, int i, int j, int k)
	{
		int l = image.getWidth(null);
		int i1 = image.getHeight(null);
		if(j > l)
			j = l;
		if(k > i1)
			k = i1;
		int ai[] = new int[l * i1];
		int ai1[] = new int[j * k];
		PixelGrabber pixelgrabber = new PixelGrabber(image, 0, 0, l, i1, ai, 0, l);
		try
		{
			pixelgrabber.grabPixels();
		}
		catch(InterruptedException interruptedexception)
		{
			System.err.println("interrupted waiting for pixels!");
			return null;
		}
		if((pixelgrabber.getStatus() & 0x80) != 0)
		{
			System.err.println("image fetch aborted or errored");
			return null;
		}
		if(i == 90)
		{
			for(int j1 = 0; j1 < j; j1++)
			{
				for(int i2 = 0; i2 < k; i2++)
					ai1[k * (j - (j1 + 1)) + i2] = ai[i2 * l + j1];

			}

			return Toolkit.getDefaultToolkit().createImage(new MemoryImageSource(k, j, ai1, 0, k));
		}
		if(i == 180)
		{
			for(int k1 = 0; k1 < j; k1++)
			{
				for(int j2 = 0; j2 < k; j2++)
					ai1[(k - (j2 + 1)) * j + (j - (k1 + 1))] = ai[j2 * l + k1];

			}

			return Toolkit.getDefaultToolkit().createImage(new MemoryImageSource(j, k, ai1, 0, j));
		}
		if(i == 270)
		{
			for(int l1 = 0; l1 < j; l1++)
			{
				for(int k2 = 0; k2 < k; k2++)
					ai1[k * l1 + (k - (k2 + 1))] = ai[k2 * l + l1];

			}

			return Toolkit.getDefaultToolkit().createImage(new MemoryImageSource(k, j, ai1, 0, k));
		} else
		{
			return null;
		}
	}

	public boolean DEBUG = false;
	public boolean MDEBUG = false;
	//public boolean DEBUG = true;
	public boolean DEBUGEAUTO = true;
	public String code;
	protected static final int d1 = 3;
	public double marginCM;
	protected int leftMarginPixels;
	protected int topMarginPixels;
	private int endOfCode;
	private int suplementTopMargin;
	public Color backColor;
	public String codeText;
	protected int narrowBarPixels;
	protected int widthBarPixels;
	protected double narrowBarCM;
	protected double widthBarCM;
	public int resolution;
	protected int barHeightPixels;
	public double N;
	public double X;
	public int width;
	public int height;
	public int pWidth;
	public int pHeight;
	public boolean autoSize;
	public Font textFont;
	public Color fontColor;
	public Color barColor;
	public double I;
	public double H;
	public double L;
	public int rotate;
	protected int currentX;
	protected int currentY;
	private int extraHeight;
	public int dotPixels;
	public int margin;
	public boolean processTilde;
	public int encoding;
	public static int E_ASCII = 0;
	public static int E_C40 = 1;
	public static int E_TEXT = 2;
	public static int E_BASE256 = 3;
	public static int E_NONE = 4;
	public static int E_AUTO = 5;
	public static String[] encName = {
		"ASCII",
		"C40",
		"TEXT",
		"BASE256",
		"NONE",
		"AUTO"
	};
	public boolean reBuild;
	private String internalCode;
	public int bitmap[][];
	public int preferredFormat;
	public static final int C10X10 = 0;
	public static final int C12X12 = 1;
	public static final int C14X14 = 2;
	public static final int C16X16 = 3;
	public static final int C18X18 = 4;
	public static final int C20X20 = 5;
	public static final int C22X22 = 6;
	public static final int C24X24 = 7;
	public static final int C26X26 = 8;
	public static final int C32X32 = 9;
	public static final int C36X36 = 10;
	public static final int C40X40 = 11;
	public static final int C44X44 = 12;
	public static final int C48X48 = 13;
	public static final int C52X52 = 14;
	public static final int C64X64 = 15;
	public static final int C72X72 = 16;
	public static final int C80X80 = 17;
	public static final int C88X88 = 18;
	public static final int C96X96 = 19;
	public static final int C104X104 = 20;
	public static final int C120X120 = 21;
	public static final int C132X132 = 22;
	public static final int C144X144 = 23;
	public static final int C8X18 = 24;
	public static final int C8X32 = 25;
	public static final int C12X26 = 26;
	public static final int C12X36 = 27;
	public static final int C16X36 = 28;
	public static final int C16X48 = 29;
	public static String[] formatName = {
		"10x10",
		"12x12",
		"14x14",
		"16x16",
		"18x18",
		"20x20",
		"22x22",
		"24x24",
		"26x26",
		"32x32",
		"36x36",
		"40x40",
		"44x44",
		"48x48",
		"52x52",
		"64x64",
		"72x72",
		"80x80",
		"88x88",
		"96x96",
		"104x104",
		"120x120",
		"132x132",
		"144x144",
		"8x18",
		"8x32",
		"12x26",
		"12x36",
		"16x36",
		"16x48",
	};
	private int currentEncoding;
	public static int C0[][] = {
		{
			10, 10, 8, 8, 1, 8, 8, 3, 5, 3, 
			5, 1
		}, {
			12, 12, 10, 10, 1, 10, 10, 5, 7, 5, 
			7, 1
		}, {
			14, 14, 12, 12, 1, 12, 12, 8, 10, 8, 
			10, 1
		}, {
			16, 16, 14, 14, 1, 14, 14, 12, 12, 12, 
			12, 1
		}, {
			18, 18, 16, 16, 1, 16, 16, 18, 14, 18, 
			14, 1
		}, {
			20, 20, 18, 18, 1, 18, 18, 22, 18, 22, 
			18, 1
		}, {
			22, 22, 20, 20, 1, 20, 20, 30, 20, 30, 
			20, 1
		}, {
			24, 24, 22, 22, 1, 22, 22, 36, 24, 36, 
			24, 1
		}, {
			26, 26, 24, 24, 1, 24, 24, 44, 28, 44, 
			28, 1
		}, {
			32, 32, 14, 14, 4, 28, 28, 62, 36, 62, 
			36, 1
		}, {
			36, 36, 16, 16, 4, 32, 32, 86, 42, 86, 
			42, 1
		}, {
			40, 40, 18, 18, 4, 36, 36, 114, 48, 114, 
			48, 1
		}, {
			44, 44, 20, 20, 4, 40, 40, 144, 56, 144, 
			56, 1
		}, {
			48, 48, 22, 22, 4, 44, 44, 174, 68, 174, 
			68, 1
		}, {
			52, 52, 24, 24, 4, 48, 48, 204, 84, 102, 
			42, 2
		}, {
			64, 64, 14, 14, 16, 56, 56, 280, 112, 140, 
			56, 2
		}, {
			72, 72, 16, 16, 16, 64, 64, 368, 144, 92, 
			36, 4
		}, {
			80, 80, 18, 18, 16, 72, 72, 456, 192, 114, 
			48, 4
		}, {
			88, 88, 20, 20, 16, 80, 80, 576, 224, 144, 
			56, 4
		}, {
			96, 96, 22, 22, 16, 88, 88, 696, 272, 174, 
			68, 4
		}, {
			104, 104, 24, 24, 16, 96, 96, 816, 336, 136, 
			56, 6
		}, {
			120, 120, 18, 18, 36, 108, 108, 1050, 496, 175, 
			68, 6
		}, {
			132, 132, 20, 20, 36, 120, 120, 1304, 496, 163, 
			62, 8
		}, {
			144, 144, 22, 22, 36, 132, 132, 1558, 620, 156, 
			62, 10
		}, {
			8, 18, 6, 16, 1, 6, 16, 5, 7, 5, 
			7, 1
		}, {
			8, 32, 6, 14, 2, 6, 28, 10, 11, 10, 
			11, 1
		}, {
			12, 26, 10, 24, 1, 10, 24, 16, 14, 16, 
			14, 1
		}, {
			12, 36, 10, 16, 2, 10, 32, 22, 18, 22, 
			18, 1
		}, {
			16, 36, 14, 16, 2, 14, 32, 32, 24, 32, 
			24, 1
		}, {
			16, 48, 14, 22, 2, 14, 44, 49, 28, 49, 
			28, 1
		}
	};
	private int rows;
	private int cols;
	private int datarows;
	private int datacols;
	private int maprows;
	private int mapcols;
	private int regions;
	private int totaldata;
	private int totalerr;
	private int reeddata;
	private int reederr;
	private int reedblocks;
	private int C49rest;
	private static int C1[][] = {
		{
			0, 0
		}, {
			0, 1
		}, {
			0, 2
		}, {
			0, 3
		}, {
			0, 4
		}, {
			0, 5
		}, {
			0, 6
		}, {
			0, 7
		}, {
			0, 8
		}, {
			0, 9
		}, {
			0, 10
		}, {
			0, 11
		}, {
			0, 12
		}, {
			0, 13
		}, {
			0, 14
		}, {
			0, 15
		}, {
			0, 16
		}, {
			0, 17
		}, {
			0, 18
		}, {
			0, 19
		}, {
			0, 20
		}, {
			0, 21
		}, {
			0, 22
		}, {
			0, 23
		}, {
			0, 24
		}, {
			0, 25
		}, {
			0, 26
		}, {
			0, 27
		}, {
			0, 28
		}, {
			0, 29
		}, {
			0, 30
		}, {
			0, 31
		}, {
			3
		}, {
			1, 0
		}, {
			1, 1
		}, {
			1, 2
		}, {
			1, 3
		}, {
			1, 4
		}, {
			1, 5
		}, {
			1, 6
		}, {
			1, 7
		}, {
			1, 8
		}, {
			1, 9
		}, {
			1, 10
		}, {
			1, 11
		}, {
			1, 12
		}, {
			1, 13
		}, {
			1, 14
		}, {
			4
		}, {
			5
		}, {
			6
		}, {
			7
		}, {
			8
		}, {
			9
		}, {
			10
		}, {
			11
		}, {
			12
		}, {
			13
		}, {
			1, 15
		}, {
			1, 16
		}, {
			1, 17
		}, {
			1, 18
		}, {
			1, 19
		}, {
			1, 20
		}, {
			1, 21
		}, {
			14
		}, {
			15
		}, {
			16
		}, {
			17
		}, {
			18
		}, {
			19
		}, {
			20
		}, {
			21
		}, {
			22
		}, {
			23
		}, {
			24
		}, {
			25
		}, {
			26
		}, {
			27
		}, {
			28
		}, {
			29
		}, {
			30
		}, {
			31
		}, {
			32
		}, {
			33
		}, {
			34
		}, {
			35
		}, {
			36
		}, {
			37
		}, {
			38
		}, {
			39
		}, {
			1, 22
		}, {
			1, 23
		}, {
			1, 24
		}, {
			1, 25
		}, {
			1, 26
		}, {
			2, 0
		}, {
			2, 1
		}, {
			2, 2
		}, {
			2, 3
		}, {
			2, 4
		}, {
			2, 5
		}, {
			2, 6
		}, {
			2, 7
		}, {
			2, 8
		}, {
			2, 9
		}, {
			2, 10
		}, {
			2, 11
		}, {
			2, 12
		}, {
			2, 13
		}, {
			2, 14
		}, {
			2, 15
		}, {
			2, 16
		}, {
			2, 17
		}, {
			2, 18
		}, {
			2, 19
		}, {
			2, 20
		}, {
			2, 21
		}, {
			2, 22
		}, {
			2, 23
		}, {
			2, 24
		}, {
			2, 25
		}, {
			2, 26
		}, {
			2, 27
		}, {
			2, 28
		}, {
			2, 29
		}, {
			2, 30
		}, {
			2, 31
		}, {
			1, 30, 0, 0
		}, {
			1, 30, 0, 1
		}, {
			1, 30, 0, 2
		}, {
			1, 30, 0, 3
		}, {
			1, 30, 0, 4
		}, {
			1, 30, 0, 5
		}, {
			1, 30, 0, 6
		}, {
			1, 30, 0, 7
		}, {
			1, 30, 0, 8
		}, {
			1, 30, 0, 9
		}, {
			1, 30, 0, 10
		}, {
			1, 30, 0, 11
		}, {
			1, 30, 0, 12
		}, {
			1, 30, 0, 13
		}, {
			1, 30, 0, 14
		}, {
			1, 30, 0, 15
		}, {
			1, 30, 0, 16
		}, {
			1, 30, 0, 17
		}, {
			1, 30, 0, 18
		}, {
			1, 30, 0, 19
		}, {
			1, 30, 0, 20
		}, {
			1, 30, 0, 21
		}, {
			1, 30, 0, 22
		}, {
			1, 30, 0, 23
		}, {
			1, 30, 0, 24
		}, {
			1, 30, 0, 25
		}, {
			1, 30, 0, 26
		}, {
			1, 30, 0, 27
		}, {
			1, 30, 0, 28
		}, {
			1, 30, 0, 29
		}, {
			1, 30, 0, 30
		}, {
			1, 30, 0, 31
		}, {
			1, 30, 3
		}, {
			1, 30, 1, 0
		}, {
			1, 30, 1, 1
		}, {
			1, 30, 1, 2
		}, {
			1, 30, 1, 3
		}, {
			1, 30, 1, 4
		}, {
			1, 30, 1, 5
		}, {
			1, 30, 1, 6
		}, {
			1, 30, 1, 7
		}, {
			1, 30, 1, 8
		}, {
			1, 30, 1, 9
		}, {
			1, 30, 1, 10
		}, {
			1, 30, 1, 11
		}, {
			1, 30, 1, 12
		}, {
			1, 30, 1, 13
		}, {
			1, 30, 1, 14
		}, {
			1, 30, 4
		}, {
			1, 30, 5
		}, {
			1, 30, 6
		}, {
			1, 30, 7
		}, {
			1, 30, 8
		}, {
			1, 30, 9
		}, {
			1, 30, 10
		}, {
			1, 30, 11
		}, {
			1, 30, 12
		}, {
			1, 30, 13
		}, {
			1, 30, 1, 15
		}, {
			1, 30, 1, 16
		}, {
			1, 30, 1, 17
		}, {
			1, 30, 1, 18
		}, {
			1, 30, 1, 19
		}, {
			1, 30, 1, 20
		}, {
			1, 30, 1, 21
		}, {
			1, 30, 14
		}, {
			1, 30, 15
		}, {
			1, 30, 16
		}, {
			1, 30, 17
		}, {
			1, 30, 18
		}, {
			1, 30, 19
		}, {
			1, 30, 20
		}, {
			1, 30, 21
		}, {
			1, 30, 22
		}, {
			1, 30, 23
		}, {
			1, 30, 24
		}, {
			1, 30, 25
		}, {
			1, 30, 26
		}, {
			1, 30, 27
		}, {
			1, 30, 28
		}, {
			1, 30, 29
		}, {
			1, 30, 30
		}, {
			1, 30, 31
		}, {
			1, 30, 32
		}, {
			1, 30, 33
		}, {
			1, 30, 34
		}, {
			1, 30, 35
		}, {
			1, 30, 36
		}, {
			1, 30, 37
		}, {
			1, 30, 38
		}, {
			1, 30, 39
		}, {
			1, 30, 1, 22
		}, {
			1, 30, 1, 23
		}, {
			1, 30, 1, 24
		}, {
			1, 30, 1, 25
		}, {
			1, 30, 1, 26
		}, {
			1, 30, 2, 0
		}, {
			1, 30, 2, 1
		}, {
			1, 30, 2, 2
		}, {
			1, 30, 2, 3
		}, {
			1, 30, 2, 4
		}, {
			1, 30, 2, 5
		}, {
			1, 30, 2, 6
		}, {
			1, 30, 2, 7
		}, {
			1, 30, 2, 8
		}, {
			1, 30, 2, 9
		}, {
			1, 30, 2, 10
		}, {
			1, 30, 2, 11
		}, {
			1, 30, 2, 12
		}, {
			1, 30, 2, 13
		}, {
			1, 30, 2, 14
		}, {
			1, 30, 2, 15
		}, {
			1, 30, 2, 16
		}, {
			1, 30, 2, 17
		}, {
			1, 30, 2, 18
		}, {
			1, 30, 2, 19
		}, {
			1, 30, 2, 20
		}, {
			1, 30, 2, 21
		}, {
			1, 30, 2, 22
		}, {
			1, 30, 2, 23
		}, {
			1, 30, 2, 24
		}, {
			1, 30, 2, 25
		}, {
			1, 30, 2, 26
		}, {
			1, 30, 2, 27
		}, {
			1, 30, 2, 28
		}, {
			1, 30, 2, 29
		}, {
			1, 30, 2, 30
		}, {
			1, 30, 2, 31
		}
	};

}