package filedirsizewritefile;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.util.Arrays;
import java.util.InputMismatchException;
import java.util.Scanner;

public class FileDirSizeWriteFile
{
    public static void main(String[] args)
    {
	int option = 0;
	Scanner scScan = new Scanner( System.in );
	boolean flag = false;
	
	while( option != 3 )
	{
	    while( ! flag )
	    {
	        System.out.println( "\n1) Full Backup\n2) Partial Backup" );

	        try
	        {
		    option = scScan.nextInt();
		    flag = true;
	        }
	        catch( InputMismatchException imEx )
	        {
		    System.out.println( "Invalid option" );
		    scScan.nextLine();
	        }
	    }
	    
	    scScan.nextLine();
	    
	    switch( option )
	    {
		case 1:
		    String fileName = "sdcard_bytes_size.txt";
		    long size = sizeOfDirectory( new File( "/sdcard" ) );
		    System.out.println( "\nSdCard Size: " + size + " bytes" );
		    createFile( fileName );
		    writeFile( fileName, String.valueOf( size ), false );
		    System.out.println( "Done." );
		break;
	    
		case 2:
		    fileName = "contents_list.txt";
		    createFile( fileName );
		    writeFile( fileName, "", true );
		    System.out.println( "Done." );
		break;
	    
		default:
		    System.out.println( "Invalid option" );
		break;
	    }
	    
	    flag = false;
	}
    }
    
    public static void createFile( String name )
    {
	File file = new File( "/sdcard/" + name );
	
	if( ! file.exists() )
	{
	    try
	    {
		file.createNewFile();
	    }
	    catch( IOException ioEx )
	    {
		    
	    }
	}
    }
    
    public static void writeFile( String name, String data, boolean append )
    {
	File file = new File( "/sdcard/" + name );
	
	PrintWriter fileWriter = null;
	
	if( append )
	{
	    try
	    {
	        fileWriter = new PrintWriter( file );
		fileWriter.print( "" );
		
		fileWriter = new PrintWriter( new FileWriter( file, append ) );		
	    }
	    catch( IOException ioEx )
	    {
		    
	    }
	    
	    File directory = new File( "/sdcard" );
	    File[] files = directory.listFiles();
	    Arrays.sort( files );
	    long size = 0L;
	    
	    for( File tempFile : files )
	    {
		size = sizeOf( tempFile );
		data = tempFile.getName() + "\t" + size;
		fileWriter.println( data );
	    }
	    fileWriter.close();
	}
	else
	{
	    try
	    {
	        fileWriter = new PrintWriter( file );
	    }
	    catch( IOException ioEx )
	    {
	    
	    }
		
	    if( data == null )
	    {
	        data = "";
	    }
	
	    fileWriter.println( data );
	    fileWriter.close();
	}
    }
    
    public static long sizeOf( final File file ) 
    {
	if ( ! file.exists() ) 
	{
            final String message = file + " does not exist";
            throw new IllegalArgumentException( message );
        }

        if ( file.isDirectory() ) 
	{
            return sizeOfDirectory0( file ); // private method; expects directory
        }
	else
	{
            return file.length();
        }
    }

    
    public static long sizeOfDirectory( final File directory ) 
    {
        checkDirectory( directory );
        return sizeOfDirectory0( directory );
    }
    
    private static void checkDirectory( final File directory ) 
    {
        if ( ! directory.exists() ) 
	{
            throw new IllegalArgumentException( directory + " does not exist" );
        }
	
        if ( ! directory.isDirectory() ) 
	{
            throw new IllegalArgumentException( directory + " is not a directory" );
        }
    }
    
    private static long sizeOfDirectory0( final File directory ) 
    {
        final File[] files = directory.listFiles();
        if ( files == null )
	{  // null if security restricted
            return 0L;
        }
	
        long size = 0;

        for ( final File file : files )
	{
            try 
	    {
                if ( ! isSymlink( file ) )
		{
                    size += sizeOf0( file ); // internal method
		    
                    if ( size < 0 )
		    {
                        break;
                    }
                }
            }
	    catch ( IOException ioe ) 
	    {
                // Ignore exceptions caught when asking if a File is a symlink.
            }
        }

        return size;
    }
    
    public static boolean isSymlink( final File file ) throws IOException 
    {
        if ( file == null ) 
	{
            throw new NullPointerException( "File must not be null" );
        }
        return Files.isSymbolicLink( file.toPath() );
    }

    private static long sizeOf0( final File file ) 
    {
        if ( file.isDirectory() )
	{
            return sizeOfDirectory0( file );
        } 
	else 
	{
            return file.length(); // will be 0 if file does not exist
        }
    }
}
