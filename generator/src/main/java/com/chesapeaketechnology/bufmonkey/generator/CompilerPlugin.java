package com.chesapeaketechnology.bufmonkey.generator;

import com.chesapeaketechnology.bufmonkey.generator.parser.ParserUtil;
import com.google.protobuf.DescriptorProtos;
import com.google.protobuf.compiler.PluginProtos.CodeGeneratorRequest;
import com.google.protobuf.compiler.PluginProtos.CodeGeneratorResponse;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.*;

/**
 * Protoc plugin that gets called by the protoc executable. The communication happens
 * via protobuf messages on System.in / System.out
 *
 * @since 0.1.0
 */
public class CompilerPlugin
{

    /**
     * Allows for configuration of the root module for files to be
     * generated under. This is useful for code generation usage
     * in monkey barrels as barrels require all class files to be located
     * under the barrel module defined in the manifest.xml file.
     */
    private static String ROOT_MODULE = "rootModule";

    /**
     * The protoc-gen-plugin communicates via proto messages on System.in and System.out
     *
     * @param args
     * @throws IOException
     */
    public static void main(String[] args) throws IOException
    {
        handleRequest(System.in).writeTo(System.out);
    }

    /**
     * Handles inputs from the the input stream to generate proto definitions in Monkey C
     *
     * @param input InputStream to read proto files from
     * @return {@link CodeGeneratorResponse} response to protobuf compiler
     */
    static CodeGeneratorResponse handleRequest(InputStream input)
    {
        try
        {
            return handleRequest(CodeGeneratorRequest.parseFrom(input));
        } catch (Exception ex)
        {
            return ParserUtil.asErrorWithStackTrace(ex);
        }
    }

    /**
     * Parses a {@link CodeGeneratorRequest} to generate proto definitions in Monkey C
     *
     * @param requestProto
     * @return {@link CodeGeneratorResponse} response to protobuf compiler
     */
    static CodeGeneratorResponse handleRequest(CodeGeneratorRequest requestProto)
    {
        CodeGeneratorResponse.Builder response = CodeGeneratorResponse.newBuilder();
        List<DescriptorProtos.FileDescriptorProto> protoFileList = requestProto.getProtoFileList();

        Map<String, String> generatorParameters = ParserUtil.getGeneratorParameters(requestProto);

        for (DescriptorProtos.FileDescriptorProto fileDescriptorProto : protoFileList)
        {
            StringWriter writer = new StringWriter();
            MonkeyWriter monkeyWriter = new MonkeyWriter(writer);
            String packageName = fileDescriptorProto.getPackage();

            List<DescriptorProtos.DescriptorProto> messageTypeList = fileDescriptorProto.getMessageTypeList();
            for (DescriptorProtos.DescriptorProto descriptorProto : messageTypeList)
            {
                String root = "BufMonkey";
                if(generatorParameters.containsKey(ROOT_MODULE)) {
                    root = generatorParameters.get(ROOT_MODULE) + "." + "BufMonkey";
                }
                monkeyWriter.writeImports(Arrays.asList("Toybox.System", root));
                monkeyWriter.writeNamespace(packageName);

                //message enums
                List<DescriptorProtos.EnumDescriptorProto> enumTypeList = descriptorProto.getEnumTypeList();
                for (DescriptorProtos.EnumDescriptorProto enumDescriptorProto : enumTypeList)
                {
                    monkeyWriter.writeModuleName(enumDescriptorProto.getName());
                    monkeyWriter.writeEnum(enumDescriptorProto.getValueList());
                    monkeyWriter.writeClosingBracket();
                }

                //message class
                String clazzName = descriptorProto.getName();
                List<DescriptorProtos.FieldDescriptorProto> fieldList = descriptorProto.getFieldList();

                monkeyWriter.writeClassName(clazzName, "BufMonkey.BufMonkeyType");
                Map<Integer, String> fieldMap = new HashMap<>();
                for (DescriptorProtos.FieldDescriptorProto fieldDescriptorProto : fieldList)
                {
                    String fieldName = fieldDescriptorProto.getName();
                    int number = fieldDescriptorProto.getNumber();
                    fieldMap.put(number, fieldName);
                    monkeyWriter.writeField(fieldName, "public");
                }

                monkeyWriter.writeConstructor(Collections.emptyList(), "BufMonkeyType",
                        Collections.singletonList(monkeyWriter.getTypeMapParam(fieldList)), null);

                monkeyWriter.writePrintFunction(clazzName, fieldList);
                monkeyWriter.writeSetValueFunction(fieldList);

                monkeyWriter.writeClosingBrackets(packageName);

                response.addFile(CodeGeneratorResponse.File.newBuilder()
                        .setName(clazzName + ".mc")
                        .setContent(writer.toString())
                        .build());

                monkeyWriter.flush();
            }

            List<DescriptorProtos.EnumDescriptorProto> enumTypeList = fileDescriptorProto.getEnumTypeList();
            for (DescriptorProtos.EnumDescriptorProto enumDescriptorProto : enumTypeList)
            {
                monkeyWriter.writeNamespace(packageName);

                monkeyWriter.writeModuleName(enumDescriptorProto.getName());
                monkeyWriter.writeEnum(enumDescriptorProto.getValueList());
                monkeyWriter.writeClosingBrackets(packageName);

                response.addFile(CodeGeneratorResponse.File.newBuilder()
                        .setName(enumDescriptorProto.getName() + ".mc")
                        .setContent(writer.toString())
                        .build());

                monkeyWriter.flush();
            }
        }

        return response.build();
    }
}
