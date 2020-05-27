package com.chesapeaketechnology.bufmonkey.generator;

import com.google.protobuf.DescriptorProtos;

import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Class which contains methods for writing Monkey C code based on parsed Protobuf inputs
 *
 * @since 0.1.0
 */
public class MonkeyWriter
{
    /**
     * The Writer object to write the code results
     */
    private final Writer writer;

    /**
     * A single indentation string
     */
    private final String INDENT = "    ";

    /**
     * The current indentation string value
     */
    private String currentIndentString = "";

    /**
     * The current indentation level
     */
    private int currentIndent = 0;

    public MonkeyWriter(Writer writer)
    {
        this.writer = writer;
    }

    /**
     * Writes a single field out to the writer object
     *
     * @param fieldName String name of the field
     * @param modifier  Access modifier
     */
    public void writeField(String fieldName, String modifier)
    {
        if (modifier != null)
        {
            writeWithIndent(modifier + " ");
        }

        writeWithNewLine("var " + fieldName + ";");
    }

    /**
     * Writes the imports for the internal and external classes
     *
     * @param imports {@link List} String list of fully qualified import names
     */
    public void writeImports(List<String> imports)
    {
        imports.forEach(importName -> writeWithNewLine("using " + importName + ";"));
        writeNewLine();
    }

    /**
     * Writes a Monkey C namespace based on the provided package name. The namespace will reside under a root Generated
     * namespace.
     *
     * @param packageName String package name read in by Protobuf
     */
    public void writeNamespace(String packageName)
    {
        String[] namespaces = packageName.split("\\.");
        for (String namespace : namespaces)
        {
            if (!namespace.equals(""))
            {
                writeModuleName(namespace);
            }
        }
    }

    /**
     * Writes a Monkey C opening class line and bracket
     *
     * @param className String name of the class
     */
    public void writeClassName(String className)
    {
        writeWithIndentAndNewLine("class " + className + " {", true);
    }

    /**
     * Writes a Monkey C opening class line that exentds from a parent class
     *
     * @param className   String name of the class
     * @param extendsFrom String name of the parent class
     */
    public void writeClassName(String className, String extendsFrom)
    {
        writeWithIndentAndNewLine("class " + className + " extends " + extendsFrom + " {", true);
    }

    /**
     * Writes a single module line
     *
     * @param moduleName String module name
     */
    public void writeModuleName(String moduleName)
    {
        writeWithIndentAndNewLine("module " + moduleName + " {", true);
    }

    /**
     * Writes a Monkey C constructor with parent initialization if provided.
     *
     * @param args List of String arguments for the constructor
     * @param parent String parent name
     * @param parentArgs List of String arguments to pass to the parent constructor
     * @param body String constructor body
     */
    public void writeConstructor(List<String> args, String parent, List<String> parentArgs, String body)
    {
        writeNewLine();
        writeWithIndent("function initialize(");
        write(String.join(",", args));
        writeWithNewLine(") {");
        increaseIndent();

        if (parent != null)
        {
            writeWithIndent(parent + ".initialize(");
            write(String.join(",", parentArgs));
            writeWithNewLine(");");
        }

        if (body != null)
        {
            write(body);
        }

        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    /**
     * Converts a List of {@link com.google.protobuf.DescriptorProtos.FieldDescriptorProto} objects to a type map
     * which maps elements based on their field number.
     *
     * @param fieldDescriptorList {@link List<com.google.protobuf.DescriptorProtos.FieldDescriptorProto>}
     * @return String formatted Type mapping
     */
    public String getTypeMapParam(List<DescriptorProtos.FieldDescriptorProto> fieldDescriptorList)
    {

        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append(System.lineSeparator());
        increaseIndent();
        increaseIndent();

        String collect = fieldDescriptorList.stream()
                .map(fieldDescriptorProto -> {
                    boolean isRepeated = fieldDescriptorProto.getLabel().equals(DescriptorProtos.FieldDescriptorProto.Label.LABEL_REPEATED);
                    int integer = fieldDescriptorProto.getNumber();

                    String typeName = "";
                    if (fieldDescriptorProto.getType().equals(DescriptorProtos.FieldDescriptorProto.Type.TYPE_MESSAGE))
                    {
                        typeName = "embedded";
                    } else
                    {
                        typeName = fieldDescriptorProto.getType().name().substring("TYPE_".length()).toLowerCase();
                    }

                    if (isRepeated)
                    {
                        return currentIndentString + integer + " => " + "[" + "\"repeated\", " + "\"" + typeName + "\"" + "]";
                    } else
                    {
                        return currentIndentString + integer + " => " + "[\"" + typeName + "\"" + "]";
                    }
                })
                .collect(Collectors.joining("," + System.lineSeparator()));

        sb.append(collect);
        sb.append(System.lineSeparator());
        decreaseIndent(1);
        sb.append(currentIndentString);
        sb.append("}");
        decreaseIndent(1);
        return sb.toString();
    }

    /**
     * Writes a print function for printing an object to the console
     *
     * @param className String name of the class containing the print method
     * @param fields {@link List<com.google.protobuf.DescriptorProtos.FieldDescriptorProto>} field list
     */
    public void writePrintFunction(String className, List<DescriptorProtos.FieldDescriptorProto> fields)
    {
        writeNewLine();
        writeWithIndentAndNewLine("function print() {", true);

        writeWithIndentAndNewLine("System.println(\"" + className + " {\");");
        for (DescriptorProtos.FieldDescriptorProto field : fields)
        {
            boolean isMessage = field.getType().equals(DescriptorProtos.FieldDescriptorProto.Type.TYPE_MESSAGE);
            writeWithIndentAndNewLine("System.println(\"     " + field.getName() + ": \" + "
                    + field.getName() + (isMessage ? ".print()" : ".toString()") + ");");
        }
        writeWithIndentAndNewLine("System.println(\"}\");");

        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    /**
     * Writes the setValue function based on the field list
     *
     * @param fieldDescriptorProtos {@link List<com.google.protobuf.DescriptorProtos.FieldDescriptorProto>} field list
     */
    public void writeSetValueFunction(List<DescriptorProtos.FieldDescriptorProto> fieldDescriptorProtos)
    {
        writeNewLine();
        writeWithIndentAndNewLine("function setValue(position, value) {", true);

        writeWithIndentAndNewLine("switch(position) {", true);

        for (DescriptorProtos.FieldDescriptorProto fieldDescriptorProto : fieldDescriptorProtos)
        {
            final int position = fieldDescriptorProto.getNumber();
            final String fieldName = fieldDescriptorProto.getName();
            boolean isMessage = fieldDescriptorProto.getType().equals(DescriptorProtos.FieldDescriptorProto.Type.TYPE_MESSAGE);

            writeWithIndentAndNewLine("case " + position + ":", true);

            if (isMessage)
            {
                String typeName = fieldDescriptorProto.getTypeName();
                if (typeName.startsWith("."))
                {
                    typeName = typeName.substring(1);
                }
                writeWithIndentAndNewLine(fieldName + " = new " + typeName + "();");
                writeWithIndentAndNewLine(fieldName + ".decode(value);");
            } else
            {
                writeWithIndentAndNewLine(fieldName + " = value;");
            }
            writeWithIndentAndNewLine("break;");
            decreaseIndent(1);
        }

        writeWithIndentAndNewLine("default:", true);
        writeWithIndentAndNewLine("System.println(\"Unknown value!\");");
        writeWithIndentAndNewLine("break;");
        decreaseIndent(2);
        writeWithIndentAndNewLine("}");
        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    /**
     * Gets the current writer string
     * @return String writer output
     */
    public String toString()
    {
        return writer.toString();
    }

    /**
     * Flushes the writer
     */
    public void flush()
    {
        if (writer instanceof StringWriter)
        {
            ((StringWriter) writer).getBuffer().setLength(0);
        } else
        {
            try
            {
                writer.flush();
            } catch (IOException e)
            {
                e.printStackTrace();
            }
        }
    }

    /**
     * Writes a single closing bracket
     */
    public void writeClosingBracket()
    {
        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    /**
     * Writes the closing brackets needed to close out the whole file
     *
     * @param packageName String package name
     */
    public void writeClosingBrackets(String packageName)
    {
        String[] namespaces = packageName.split("\\.");
        for (String namespace : namespaces)
        {
            if (!namespace.equals(""))
            {
                decreaseIndent(1);
                writeWithIndentAndNewLine("}");
            }
        }

        //One to close the class
        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    /**
     * Writes a String with the current indentation
     *
     * @param s String to write
     */
    private void writeWithIndent(String s)
    {
        writeWithIndent(s, false);
    }

    /**
     * Writes a String and then increases the indentation if desired
     *
     * @param s String to write
     * @param increaseIndent whether or not to increase the indentation level
     */
    private void writeWithIndent(String s, boolean increaseIndent)
    {
        write(currentIndentString + s);
        if (increaseIndent)
        {
            increaseIndent();
        }
    }

    /**
     * Writes a String to the output
     *
     * @param s String to write
     */
    private void write(String s)
    {
        try
        {
            writer.write(s);
        } catch (IOException e)
        {
            System.out.println("Unable to write the line(s) to the writer due to: " + e.getMessage());
        }
    }

    /**
     * Writes a String with the current indentation and with a new line
     *
     * @param s String to write
     */
    private void writeWithIndentAndNewLine(String s)
    {
        writeWithIndentAndNewLine(s, false);
    }

    /**
     * Writes a String with and indentation if desired and with a new line
     *
     * @param s String to write
     * @param increaseIndent Boolean whether or not to increase the indentation level
     */
    private void writeWithIndentAndNewLine(String s, boolean increaseIndent)
    {
        writeWithIndent(s, increaseIndent);
        writeNewLine();
    }

    /**
     * Increases the indentation level
     */
    private void increaseIndent()
    {
        currentIndent++;
        currentIndentString = "";
        for (int i = 0; i < currentIndent; i++)
        {
            currentIndentString += INDENT;
        }
    }

    /**
     * Decreases the indentation level
     *
     * @param numTimes int number of times to decrease the indentation
     */
    private void decreaseIndent(int numTimes)
    {
        currentIndent -= numTimes;
        if (currentIndent < 0)
        {
            currentIndent = 0;
        }
        currentIndentString = "";
        for (int i = 0; i < currentIndent; i++)
        {
            currentIndentString += INDENT;
        }
    }

    /**
     * Writes a string to the Writer with a new line
     *
     * @param s String to write
     */
    private void writeWithNewLine(String s)
    {
        write(s + System.lineSeparator());
    }

    /**
     * Writes a new line to the Writer
     */
    private void writeNewLine()
    {
        write(System.lineSeparator());
    }

    /**
     * Writes an Enum type
     *
     * @param enums {@link List<com.google.protobuf.DescriptorProtos.EnumValueDescriptorProto>} enum values
     */
    public void writeEnum(List<DescriptorProtos.EnumValueDescriptorProto> enums)
    {
        writeWithIndentAndNewLine("enum {", true);
        String enumStrings = enums.stream().map(anEnum -> currentIndentString + anEnum.getName()
                + " = " + anEnum.getNumber())
                .collect(Collectors.joining("," + System.lineSeparator()));
        writeWithNewLine(enumStrings);
        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }
}
