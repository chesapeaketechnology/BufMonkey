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
 * @author Florian Enner
 * @since 05 Aug 2019
 */
public class CompilerPlugin {

    /**
     * The protoc-gen-plugin communicates via proto messages on System.in and System.out
     *
     * @param args
     * @throws IOException
     */
    public static void main(String[] args) throws IOException {
        handleRequest(System.in).writeTo(System.out);
    }

    static CodeGeneratorResponse handleRequest(InputStream input) throws IOException {
        try {
            return handleRequest(CodeGeneratorRequest.parseFrom(input));
        } catch (Exception ex) {
            return ParserUtil.asErrorWithStackTrace(ex);
        }
    }

    static CodeGeneratorResponse handleRequest(CodeGeneratorRequest requestProto) {
        CodeGeneratorResponse.Builder response = CodeGeneratorResponse.newBuilder();


        Map<String, String> generatorParameters = ParserUtil.parseGeneratorParameters(requestProto.getParameter());

        List<DescriptorProtos.FileDescriptorProto> protoFileList = requestProto.getProtoFileList();

        for (DescriptorProtos.FileDescriptorProto fileDescriptorProto : protoFileList)
        {
            StringWriter writer = new StringWriter();

            MonkeyWriter monkeyWriter = new MonkeyWriter(writer, fileDescriptorProto);

            String packageName = fileDescriptorProto.getPackage();
            //List<DescriptorProtos.FieldDescriptorProto> extensionList = fileDescriptorProto.getExtensionList();

            String name = fileDescriptorProto.getName();

            List<DescriptorProtos.DescriptorProto> messageTypeList = fileDescriptorProto.getMessageTypeList();
            for (DescriptorProtos.DescriptorProto descriptorProto : messageTypeList)
            {
                String clazzName = descriptorProto.getName();
                int fieldCount = descriptorProto.getFieldCount();
                List<DescriptorProtos.FieldDescriptorProto> fieldList = descriptorProto.getFieldList();

                try
                {

                    monkeyWriter.writeImports(Arrays.asList("Toybox.System", "BufMonkey.BufMonkeyType"));
                    monkeyWriter.writeNamespace(packageName);
                    monkeyWriter.writeClassName(clazzName, "BufMonkeyType");
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

                    List<String> fieldNames = new ArrayList<>(fieldMap.values());
                    monkeyWriter.writeToStringFunction(clazzName, fieldNames);
                    monkeyWriter.writeSetValueFunction(fieldMap);

                    monkeyWriter.writeClosingBrackets(packageName);

                } catch (IOException e) {
                    e.printStackTrace();
                }


                response.addFile(CodeGeneratorResponse.File.newBuilder()
                        .setName(clazzName + ".mc")
                        .setContent(writer.toString())
                        .build());
            }

            //
            String[] split = fileDescriptorProto.getPackage().split("\\.");

            try
            {
                monkeyWriter.flush();
            } catch (IOException e)
            {
                e.printStackTrace();
            }
        }



//        for (RequestInfo.FileInfo file : request.getFiles()) {
//
//            // Generate type specifications
//            List<TypeSpec> topLevelTypes = new ArrayList<>();
//            TypeSpec.Builder outerClassSpec = TypeSpec.classBuilder(file.getOuterClassName());
//            Consumer<TypeSpec> list = file.isGenerateMultipleFiles() ? topLevelTypes::add : outerClassSpec::addType;
//
//            for (RequestInfo.EnumInfo type : file.getEnumTypes()) {
//                list.accept(new EnumGenerator(type).generate());
//            }
//
//            for (RequestInfo.MessageInfo type : file.getMessageTypes()) {
//                list.accept(new MessageGenerator(type).generate());
//            }
//
//            // Omitt completely empty outer classes
//            if (!file.isGenerateMultipleFiles()) {
//                topLevelTypes.add(outerClassSpec.build());
//            }
//
//            // Generate Java files
//            for (TypeSpec typeSpec : topLevelTypes) {
//
//                JavaFile javaFile = JavaFile.builder(file.getJavaPackage(), typeSpec)
//                        .addFileComment("Code generated by protocol buffer compiler. Do not edit!")
//                        .indent(request.getIndentString())
//                        .skipJavaLangImports(true)
//                        .build();
//
//                StringBuilder content = new StringBuilder(1000);
//                try {
//                    javaFile.writeTo(content);
//                } catch (IOException e) {
//                    throw new AssertionError("Could not write to StringBuilder?");
//                }
//
//                response.addFile(CodeGeneratorResponse.File.newBuilder()
//                        .setName(file.getOutputDirectory() + typeSpec.name + ".java")
//                        .setContent(content.toString())
//                        .build());
//            }
//
//        }

        return response.build();

    }

//    public static String getIndentString(String indent) {
//        switch (indent) {
//            case "8":
//                return "        ";
//            case "4":
//                return "    ";
//            case "2":
//                return "  ";
//            case "tab":
//                return "\t";
//        }
//        throw new GeneratorException("Expected 2,4,8,tab. Found: " + indent);
//    }

}
