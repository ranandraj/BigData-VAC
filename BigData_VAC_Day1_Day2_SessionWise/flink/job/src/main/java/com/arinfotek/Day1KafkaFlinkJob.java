package com.arinfotek;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

public class Day1KafkaFlinkJob {
  public static void main(String[] args) throws Exception {
    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
    KafkaSource<String> source = KafkaSource.<String>builder()
        .setBootstrapServers("kafka:29092")
        .setTopics("ecommerce-events")
        .setGroupId("day1-flink-students")
        .setStartingOffsets(OffsetsInitializer.earliest())
        .setValueOnlyDeserializer(new SimpleStringSchema())
        .build();

    DataStream<String> events = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka E-Commerce Events");
    events.filter(e -> e.toLowerCase().contains("order_created"))
          .map(e -> "[FLINK ORDER EVENT] " + e)
          .print();

    env.execute("Day 1 Kafka to Flink E-Commerce Orders");
  }
}
