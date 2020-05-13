package com.chesapeaketechnology.bufmonkey.generator;

import com.google.protobuf.DescriptorProtos;

import java.io.IOException;
import java.io.Writer;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * TODO: class description
 *
 * @since
 */
public class MonkeyWriter
{
    private final Writer writer;
    private final String fileName;

    private final String INDENT = "    ";
    private final int INDENT_SIZE = INDENT.length();
    private String currentIndentString = "";
    private int currentIndent = 0;

    public MonkeyWriter(Writer writer, DescriptorProtos.FileDescriptorProto descriptor)
    {
        this.writer = writer;
        this.fileName = descriptor.getName();
        //this.protoPackage = NamingUtil.getProtoPackage(descriptor);

//        this.javaPackage = getParentRequest().applyJavaPackageReplace(
//                NamingUtil.getJavaPackage(descriptor));

        //this.outerClassName = ClassName.get(javaPackage, NamingUtil.getJavaOuterClassname(descriptor));

        //this.outputDirectory = javaPackage.isEmpty() ? "" : javaPackage.replaceAll("\\.", "/") + "/";

//        DescriptorProtos.FileOptions options = descriptor.getOptions();
//        this.generateMultipleFiles = options.hasJavaMultipleFiles() && options.getJavaMultipleFiles();
//        this.deprecated = options.hasDeprecated() && options.getDeprecated();
//
//        this.baseTypeId = "." + protoPackage;
//
//        this.messageTypes = descriptor.getMessageTypeList().stream()
//                .map(desc -> new MessageInfo(this, baseTypeId, outerClassName, !generateMultipleFiles, desc))
//                .collect(Collectors.toList());
//
//        enumTypes = descriptor.getEnumTypeList().stream()
//                .map(desc -> new EnumInfo(this, baseTypeId, outerClassName, !generateMultipleFiles, desc))
//                .collect(Collectors.toList());
    }

    /**
     * Writes the field out
     *
     * @param fieldName
     */
    public void writeField(String fieldName, String modifier) throws IOException
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
     * @param imports
     */
    public void writeImports(List<String> imports) throws IOException
    {
        imports.forEach(importName -> {
            try
            {
                writeWithNewLine("using " + importName + ";");
            } catch (IOException e)
            {
                e.printStackTrace();
            }
        });
        writeNewLine();
    }

    public void writeNamespace(String packageName) throws IOException
    {
        writeWithIndentAndNewLine("module Generated {", true);
        String[] namespaces = packageName.split("\\.");
        for (String namespace : namespaces)
        {
            if (!namespace.equals(""))
            {
                writeWithIndentAndNewLine("module " + namespace + " {", true);
            }
        }

        writeNewLine();
    }

    public void writeClassName(String className) throws IOException
    {
        writeWithIndentAndNewLine("class " + className + " {", true);
    }

    public void writeClassName(String className, String extendsFrom) throws IOException
    {
        writeWithIndentAndNewLine("class " + className + " extends " + extendsFrom + " {", true);
    }

    public void writeConstructor(List<String> args, String parent, List<String> parentArgs, String body) throws IOException
    {
        writeNewLine();
        writeWithIndent("function initialize(");
        writer.write(String.join(",", args));
        writeWithNewLine(") {");
        increaseIndent();

        if (parent != null)
        {
            writeWithIndent(parent + ".initialize(");
            writer.write(String.join(",", parentArgs));
            writeWithNewLine(");");
        }

        if (body != null)
        {
            writer.write(body);
        }

        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    public String getTypeMapParam(Map<Integer, String> typeMap)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append(System.lineSeparator());
        increaseIndent();
        increaseIndent();

        String collect = typeMap.entrySet().stream()
                .map(integerStringEntry -> {
                    Integer integer = integerStringEntry.getKey();
                    String s = integerStringEntry.getValue();
                    return currentIndentString + integer + " => " + "\"" + s + "\"";
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

    public void writeToStringFunction(String className, List<String> fields) throws IOException
    {
        writeNewLine();
        writeWithIndentAndNewLine("function toString() {", true);

        writeWithIndentAndNewLine("System.println(\"" + className + " {\");");
        for (String field : fields)
        {
            writeWithIndentAndNewLine("System.println(\"     " + field + ": \" + " + field + ");");
        }
        writeWithIndentAndNewLine("System.println(\"}\");");

        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    public void writeSetValueFunction(Map<Integer, String> fieldNames) throws IOException
    {
        writeNewLine();
        writeWithIndentAndNewLine("function setValue(position, value) {", true);

        writeWithIndentAndNewLine("switch(position) {", true);

        for (Map.Entry<Integer, String> fieldNameEntry : fieldNames.entrySet())
        {
            final int position = fieldNameEntry.getKey();
            final String fieldName = fieldNameEntry.getValue();

            writeWithIndentAndNewLine("case " + position + ":", true);
            writeWithIndentAndNewLine(fieldName + " = value;");
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

    public String toString()
    {
        return writer.toString();
    }

    public void flush() throws IOException
    {
        writer.flush();
    }

    public void writeClosingBrackets(String packageName) throws IOException
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

        //One to close the module
        decreaseIndent(1);
        writeWithIndentAndNewLine("}");
    }

    private void writeWithIndent(String s) throws IOException
    {
        writeWithIndent(s, false);
    }

    private void writeWithIndent(String s, boolean increaseIndent) throws IOException
    {
        writer.write(currentIndentString + s);
        if (increaseIndent)
        {
            increaseIndent();
        }
    }

    private void writeWithIndentAndNewLine(String s) throws IOException
    {
        writeWithIndentAndNewLine(s, false);
    }

    private void writeWithIndentAndNewLine(String s, boolean increaseIndent) throws IOException
    {
        writeWithIndent(s, increaseIndent);
        writeNewLine();
    }

    private void increaseIndent()
    {
        currentIndent++;
        currentIndentString = "";
        for (int i = 0; i < currentIndent; i++)
        {
            currentIndentString += INDENT;
        }
    }

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

    private void writeWithNewLine(String s) throws IOException
    {
        writer.write(s + System.lineSeparator());
    }

    private void writeNewLine() throws IOException
    {
        writer.write(System.lineSeparator());
    }
}
