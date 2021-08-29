package com.google.sp1.demo;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
@RestController
public class ColorController {
    
    HashMap<String, String> map = new HashMap<>();
    private final WebClient webClient;

    public ColorController(WebClient.Builder webClientBuilder)
    {
        this.webClient = webClientBuilder.baseUrl("http://metadata.google.internal/computeMetadata/v1/")
                .defaultHeaders(httpHeaders -> {
                    httpHeaders.add("Metadata-Flavor" , "Google");
                })
                .build();
    }

    @GetMapping("/color")
    public String color() {
        return "blue";
    }

    @GetMapping("/metadata")
    public Map<String, String> metadata() {
        
        if (map.isEmpty()) {

            String cluster_name = webClient.get().uri("instance/attributes/cluster-name").retrieve().bodyToMono(String.class)
                    .block();
            map.put("CLUSTER_NAME", cluster_name);
            String instance = webClient.get().uri("instance/zone").retrieve().bodyToMono(String.class).block();
            map.put("INSTANCE/ZONE", instance);
            String hostname = webClient.get().uri("instance/hostname").retrieve().bodyToMono(String.class).block();
            map.put("HOSTNAME", hostname);
            map.put("POD_IP", System.getenv().get("POD_IP"));
            map.put("POD_NAMESPACE", System.getenv().get("POD_NAMESPACE"));
            String project = webClient.get().uri("project/project-id").retrieve().bodyToMono(String.class).block();
            map.put("PROJECT_ID", project);
    
            
        }
        return map;
    }

}