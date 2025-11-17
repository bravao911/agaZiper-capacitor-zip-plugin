package com.aga.zipper.plugin.zip;

import com.getcapacitor.Logger;

public class Zip {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
