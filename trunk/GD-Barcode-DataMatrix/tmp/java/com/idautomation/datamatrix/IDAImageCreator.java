// Decompiled by DJ v3.9.9.91 Copyright 2005 Atanas Neshkov  Date: 18.01.2007 8:28:08
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   com/idautomation/datamatrix/IDAImageCreator

package com.idautomation.datamatrix;

import java.awt.Graphics;
import java.awt.Image;
import java.awt.image.BufferedImage;

public class IDAImageCreator
{

    public IDAImageCreator()
    {
    }

    public Image getImage(int i, int j)
    {
        int k = i;
        if(j > i)
            k = j;
        im = new BufferedImage(k, k, 13);
        g = ((BufferedImage)im).createGraphics();
        return im;
    }

    public Graphics getGraphics()
    {
        return g;
    }

    private Image im;
    public Graphics g;
}