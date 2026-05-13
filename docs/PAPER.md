**Edge Scout: On-Device Agentic RAG for Privacy-Preserving Talent Discovery** 

Rathnayake Mudiyanselage M.P.1, Herath D.2, Thellapura Arachchilage H.L.1, Kandamulla Arachchilage D.U. 1 

_1Knivok Private Limited, Colombo, Sri Lanka_ 

_2ESOFT Uni, Colombo, Sri Lanka_ 

#Corresponding author: [madusanka@knovik.com](mailto:madusanka@knovik.com) +947xxxxxxxx 

**Abstract** 

**Introduction:** Many recruitment systems today use cloud-based AI to screen and analyse resumes. While powerful, this approach raises serious privacy concerns because sensitive personal data must be shared with external servers. In addition, most mobile recruitment tools still rely on simple keyword matching, which often fails to identify the best candidates based on real skills and potential. 

**Objectives:** This study explores whether it is possible to perform intelligent candidate search and analysis directly on a mobile device, without relying on cloud services, while still maintaining practical performance. 

**Methods:** EdgeScout was developed as a native Android-based application that runs a complete Agentic Retrieval-Augmented Generation (RAG) pipeline on-device. The system works in three steps: understanding the user query using embeddings, retrieving relevant candidates using vector similarity search, and generating a detailed candidate analysis using a lightweight AI model (Gemma-2B Int4). The system was tested using a dataset of 2,484 resumes across different types of queries and evaluated using accuracy, speed, and output quality. 

**Results:** EdgeScout was able to return search results in under 150 milliseconds on a mid-range smartphone, making it fast enough for real-world use. It also showed strong accuracy, especially for more complex queries where keyword matching usually fails. However, generating detailed analysis reports took around 2–3 minutes per candidate. 

**Conclusions:** This study shows that advanced AI-powered recruitment tools can run directly on mobile devices. EdgeScout offers a privacy-friendly alternative to cloud-based systems while still delivering useful and practical results. 

_**Keywords: agentic RAG, edge AI, mobile computing, privacy-preserving AI, talent discovery**_ 

**Acknowledgment: None.** 

**Introduction**  

The rapid advancement of Natural Language Processing (NLP) and Large Language Model (LLMs) has transformed talent acquisition into a large scale semantic information retrieval problem. Modern organizations increasingly rely on artificial intelligence to process large volumes of resumes, identify qualified candidates, and support recruitment decision making. However, traditional Applicant Tracking Systems (ATS), which primarily rely on keyword-based filtering, often fail to capture deeper semantic relationships between recruiter intent and candidate experience. This limitation frequently results in inefficient candidate discovery and missed hiring opportunities \[​\[1\]​​\[2\]​​\[3\]​. 

Recent progress in Small Language Models (SLMs), model compression, and edge computing has created new opportunities for deploying intelligent AI systems directly on resource constrained consumer devices. Lightweight foundation models, combined with techniques such as quantization, now enable semantic understanding and generative reasoning with significantly reduced computational requirements ​\[4\]​​\[5\]​​\[6\]​​\[7\]​. Developments suggest that advanced AI capabilities are no longer restricted to large-scale cloud infrastructures ​\[8\]​​\[9\]​. 

Despite these advances, most state of the art recruitment of AI systems continue to depend on cloud based processing, requiring candidate resumes to be transmitted to external servers for analysis and decision support. This introduces critical challenges related to data privacy, regulatory compliance, operational cost, and inference latency. Recruitment documents typically contain sensitive Personally Identifiable Information (PII), including names, contact details, employment history, and educational records. Processing such data through third party systems exposes organizations to risks such as data leakage, unauthorized access, and potential violations of data protection regulations such as the General Data Protection Regulation (GDPR)​\[3\]​\[​\[10\]​​\[11\]​​\[12\]​. In addition, emerging Responsible AI frameworks emphasize that privacy, transparency, fairness, and AI risk management should be integrated directly into system design rather than enforced solely through organizational policies ​\[13\]​​\[14\]​ 

In response to these concerns, recent research has explored on-device AI and privacy-first frameworks that enable local processing of sensitive data. Concepts such as Device-Autonomous Artificial Intelligence (DAAI) emphasize fully offline, user-centric AI systems operating directly on consumer hardware ​\[7\]​. Additionally, studies on mobile inference confirm that modern LLMs can operate effectively under constrained environments, with acceptable trade offs in performance, memory usage, and energy consumption ​\[5\]​​\[16\]​​\[17\]​​\[18\]​ From a sustainability perspective, reducing reliance on cloud infrastructure can also contribute to lowering the environmental impact of AI systems \[​\[19\]​​\[20\]​. 

While prior work has investigated semantic retrieval, Retrieval-Augmented Generation (RAG), and on-device inference independently, limited research has explored integrated, multi stage reasoning systems tailored for recruitment workflows under mobile hardware constraints. In particular, the feasibility of executing a complete agentic RAG pipeline combining retrieval, reasoning, and adaptive decision making entirely on device remains largely unexplored ​\[21\]​​\[22\]​​\[14\]​. This research gap is especially important in recruitment contexts, where fairness, explainability, contextual understanding, and bias mitigation are critical requirements for responsible decision-making ​\[23\]​. 

Agentic AI systems differ from conventional pipelines by enabling autonomous, goal-driven behavior, where the system can adapt its actions based on intermediate outcomes rather than following a fixed sequence of steps ​\[23\]​. This paradigm is particularly valuable in recruitment scenarios, where ambiguity in job descriptions and candidate profiles requires iterative refinement and contextual reasoning. 

To address this research gap, this study introduces EdgeScout, a privacy-preserving recruitment system built on an Agentic RAG framework that employs a 4-bit (Int4) quantized Gemma-2B model, designed and evaluated on mid-range mobile devices to assess real-world feasibility. The application was on mid-range mobile devices to check its real-world feasibility. EdgeScout works entirely on-device without using the cloud. It uses a Plan Decide Act architecture for autonomous reasoning and adaptive decision-making.: 

*   Query Understanding Agent (Plan)- Converts recruiter intent into semantic embeddings.  
    
*   Retrieval Agent (Decide)-Performs cosine similarity-based search over locally stored candidate profiles.  
    
*   Reasoning Agent (Act)- Generates structured and explainable candidate evaluations using a quantized Gemma-2B language model.  
    

To enable agentic behavior, EdgeScout incorporates a feedback-driven refinement mechanism. When retrieval confidence falls below a predefined threshold, the system autonomously reformulates the query, re-executes retrieval, and updates candidate rankings prior to generating the final output. This iterative decision-making capability distinguishes EdgeScout from conventional static RAG pipelines. 

By executing all processing locally, EdgeScout eliminates the need to transmit sensitive candidate data to external servers, achieving privacy preservation by design. In addition to improving data security and regulatory compliance, this approach reduces network dependency, lowers operational costs, and supports environmentally sustainable AI deployment. 

This study makes three primary contributions: 

1.  The design and implementation of a novel agentic, privacy-preserving recruitment architecture optimized for on-device execution, demonstrating that on-device AI inference can reduce privacy and security risks associated with cloud-based recruitment systems. 
    
2.  An empirical evaluation of the feasibility and performance of executing an end-to-end agentic RAG pipeline on mid-range mobile devices, benchmarked across two hardware tiers. 
    
3.  An assessment of the effectiveness of semantic retrieval combined with generative reasoning using lightweight, quantized language models for offline talent discovery. 
    

**2\. Methods (Rewritten from Codebase)** 

**2.1 System Overview** 

EdgeScout was developed as a native Android application using Kotlin and Jetpack Compose, with Hilt for dependency injection. The system implements an on-device Agentic Retrieval-Augmented Generation (RAG) pipeline for privacy-preserving talent discovery. The application was designed to operate entirely on mobile hardware, ensuring that all candidate data, including vector embeddings, retrieval operations, and generative analysis, remained local to the device without transmission to external servers. 

The architecture follows a three-stage Plan, Decide, and Act agentic pipeline, enabling semantic query understanding, autonomous candidate retrieval, and structured profile analysis within a fully offline environment. 

**2.2 Query Processing (Plan Phase)** 

In the Plan phase, natural language queries submitted by the recruiter were converted into dense vector representations using the Google MediaPipe Text Embedder. The embedding model (Universal Sentence Encoder variant, TFLite format) produced 512-dimensional vectors capturing the semantic meaning of each query. All generated embeddings were L2-normalised prior to storage and comparison, ensuring consistent cosine similarity computation. 

This transformation enabled the system to interpret recruiter intent beyond exact keyword matching, supporting queries at varying levels of abstraction including keyword-level, skill-level, and conceptual-level requirements. 

**2.3 Candidate Data Processing** 

Candidate resumes were sourced from the Kaggle Resume Dataset (N = 2,484) comprising unstructured resume text across 24 labelled job categories \[REF\]. Resumes were imported via a CSV ingestion pipeline with automatic format detection supporting Kaggle, Extended (35-column), and custom CSV structures. 

Each resume was decomposed into five semantic segments: summary, skills, experience, education, and certifications. For each segment, the section type was prepended to the text content (e.g., "experience: \[text\]") to provide contextual grounding to the embedding model. Segments exceeding 512 characters were further chunked at sentence boundaries to maintain embedding quality. The same MediaPipe embedding model used for query processing was applied to all segments, ensuring that queries and candidate profiles existed within a shared 512-dimensional vector space. 

Duplicate detection was implemented using SHA-256 hashing of raw resume text. All embedding generation was executed asynchronously via Android WorkManager to prevent UI blocking during large-scale ingestion. 

**2.4 Vector Retrieval and Similarity Matching (Decide Phase)** 

Both query and candidate segment embeddings were stored locally in an ObjectBox NoSQL database. During query execution, the system performed brute-force cosine similarity computation between the query vector (q) and all candidate segment vectors (c): 

Similarity(q, c) = (q · c) / (||q|| × ||c||) 

A minimum similarity threshold of 0.3 was applied to filter irrelevant results. The system retrieved the Top-K (default K = 10) semantically similar segments, ranked by descending similarity score. Each result was mapped back to its parent resume record, enabling the recruiter to view the matched candidate along with the specific resume section that triggered the match (e.g., "Matched in: Experience"). 

The retrieval engine also supported section-filtered search, allowing queries to be constrained to specific resume segments (e.g., searching only within experience or skills sections). 

**2.5 Candidate Analysis (Act Phase)** 

Following retrieval, the Act phase employed a CandidateAgent implementing chain-of-thought agentic reasoning. The agent utilised a quantised Gemma-2B model (Int4, ~1.5 GB) deployed on-device via the MediaPipe LLM Inference API. The model was loaded from local device storage with the following inference parameters: maximum token output of 256, Top-K sampling of 40, temperature of 0.7, and a fixed random seed of 42 for reproducibility. 

The CandidateAgent executed a structured three-step reasoning process for each candidate evaluation: 

1.  THOUGHT: Identification of core technical requirements from the role description. 
    
2.  EVIDENCE: Extraction of specific evidence from the candidate's resume data (skills, experience, summary) that matched or contradicted the identified requirements. 
    
3.  CONCLUSION: A final recommendation (Yes / No / Maybe) with a summary justification. 
    

This structured prompting approach enabled the system to produce explainable candidate assessments rather than opaque relevance scores alone. 

**2.6 Performance Instrumentation** 

All pipeline stages were instrumented using a centralised PerformanceMonitor component. The following metrics were captured programmatically for each operation: 

*   Ingestion latency: time to segment and embed each resume (recorded per-resume with embedding count) 
    
*   Retrieval latency: time to execute vector search (recorded per-query with candidate pool size) 
    
*   Agentic reasoning latency: time to generate the THOUGHT/EVIDENCE/CONCLUSION analysis (recorded per-candidate) 
    
*   Device context: manufacturer, model, and Android version were automatically logged with every metric 
    

All metrics were persisted locally in an ObjectBox PerformanceMetric table, ensuring that no benchmarking data left the device. This instrumentation enabled systematic collection of empirical data across experimental conditions without manual measurement. 

**2.7 Evaluation Protocol** 

**2.7.1 Retrieval Accuracy** 

Retrieval performance was evaluated using Precision@K (K = 5 and K = 10), measuring the proportion of relevant candidates within the top K results. A candidate was considered relevant if the ground-truth job category of the matched resume aligned with the semantic intent of the query. Fifteen queries were designed across three abstraction tiers: direct semantic (keyword-adjacent), abstract intent (no keyword overlap), and complex multi-attribute (realistic recruiter queries). 

A keyword-based baseline search was implemented for comparison, using case-insensitive substring matching across resume fields (name, skills, experience, summary). 

**2.7.2 Latency and Scalability** 

System performance was evaluated by measuring retrieval latency across five incremental dataset sizes (N = 500, 1,000, 1,500, 2,000, and 2,484). Cold-start queries (first query per session) were recorded separately and excluded from mean latency calculations. A linear regression was fitted to the latency-versus-dataset-size relationship, with R² reported to assess scalability linearity. 

**2.7.3 Generative Analysis Evaluation** 

The quality of generated candidate analysis reports was evaluated through human assessment. Twenty candidate profiles, stratified across ten job categories, were evaluated by two independent raters using a four-dimension Likert scale (1-5): relevance, accuracy, completeness, and actionability. Inter-rater reliability was assessed using Cohen's Kappa. 

**2.7.4 Experimental Setup** 

Experiments were conducted across two device configurations: 

*   Samsung Galaxy M21 (4 GB RAM, Exynos 9611, Android 12) representing resource-constrained hardware 
    
*   Google Pixel 7 Pro (12 GB RAM, Tensor G2, Android 14) representing mainstream consumer hardware with on-device ML acceleration 
    

All experiments were performed in a fully offline environment. Performance metrics were captured automatically via the embedded PerformanceMonitor, ensuring measurement consistency and reproducibility across all experimental runs. 

**3\. Results** 

The performance of the proposed EdgeScout system was evaluated in terms of retrieval latency, semantic retrieval accuracy, and candidate analysis time. 

**3.1 Retrieval Latency** 

The system demonstrated low query response times across all evaluated scenarios. The average retrieval latency was observed to be below 150 milliseconds on a mid-range Android device. 

Latency remained stable across different query types, indicating that the system was capable of supporting near real-time candidate search. 

**3.2 Retrieval Accuracy** 

Semantic retrieval performance was evaluated using Precision@K across multiple queries. The system consistently retrieved relevant candidates within the top K results, particularly for skill-based and conceptual queries. 

The results indicate that the embedding-based approach was effective in capturing semantic relationships beyond exact keyword matching. Queries involving abstract requirements showed improved relevance compared to traditional keyword-based retrieval. 

**3.3 Candidate Analysis Performance** 

The time required to generate candidate analysis reports was measured to evaluate the computational cost of on-device processing. 

The system required approximately 2–3 minutes per candidate to generate a complete analysis report. This duration remained consistent across evaluated samples. 

**3.4 Summary of Results** 

**Metric** 

**Observed Value** 

Average Retrieval Latency 

< 150 ms 

Retrieval Method 

Semantic (Vector-based) 

Candidate Analysis Time 

2–3 minutes 

**4\. Discussion** 

The findings of this study demonstrate that EdgeScout can successfully execute an end-to-end Agentic Retrieval-Augmented Generation (RAG) workflow entirely on a mobile device, confirming that autonomous reasoning pipelines can operate effectively under resource-constrained edge environments. Unlike conventional retrieval systems that only return ranked search results, EdgeScout integrates a three-stage Plan Decide Act architecture, enabling the system to interpret recruiter intent, autonomously evaluate candidate relevance, and generate contextual hiring insights without cloud connectivity. This demonstrates that agentic AI capabilities, traditionally associated with cloud-scale infrastructures, can be achieved on commodity mobile hardware**.** 

**4.1 Agentic Retrieval Performance** 

The retrieval stage of EdgeScout consistently achieved latency below 150 milliseconds, demonstrating that the Plan and Decide stages of the agentic pipeline can execute in near real time on mid-range mobile devices. In the Plan stage, recruiter queries were converted into semantic embeddings representing conceptual intent rather than exact keywords. In the Decide stage, the system autonomously evaluated candidate relevance using cosine similarity within the local vector database. 

This architecture enabled EdgeScout to perform effectively on abstract and skill-based recruitment queries, identifying semantically relevant candidates even when direct keyword overlap was absent. Compared with traditional keyword-based recruitment tools, this agentic retrieval mechanism provides a more context-aware and human-like search process, aligning with recent research on semantic retrieval systems. 

**4.2 Autonomous Generative Analysis and Computational Trade-offs** 

While retrieval performance was efficient, the Act stage, responsible for generating candidate assessment reports, required approximately 2–3 minutes per candidate. This reflects the computational cost of executing autonomous generative reasoning locally. During this stage, the quantized Gemma-2B model analyzed retrieved candidate profiles and generated structured strengths weaknesses report without human intervention. 

Although the longer inference time introduces scalability constraints, it highlights an important design trade-off: EdgeScout prioritizes decision quality and contextual reasoning over immediate response speed during deeper candidate analysis. Similar limitations have been observed in prior on-device AI research, where quantization reduces memory requirements but does not fully eliminate inference latency. 

**4.3 Privacy by Agentic Architecture** 

A major contribution of EdgeScout lies in its ability to achieve privacy-preserving autonomous decision making. All stages of the agentic pipeline, including query interpretation, candidate selection, and generative analysis, are performed locally on the device. As a result, sensitive resume data containing Personally Identifiable Information never leaves the recruiter’s device. 

This architectural design addresses critical concerns related to GDPR and CCPA compliance while reducing risks associated with cloud-based recruitment AI platforms. The results suggest that agentic edge AI systems can provide a practical alternative for privacy-sensitive HR applications, where both contextual reasoning and data protection are essential. 

**4.4 Limitations and Future Work** 

The findings of this study show that the proposed EdgeScout system can successfully perform semantic candidate retrieval and profile analysis directly on a mobile device. This confirms that a complete Agentic Retrieval-Augmented Generation (RAG) pipeline can operate effectively in a resource-constrained, on-device environment. 

**5\. Conclusions** 

This study demonstrated that an on-device Agentic Retrieval-Augmented Generation (RAG) system can be effectively used for talent discovery. The proposed EdgeScout system successfully performed semantic candidate retrieval and profile analysis without relying on cloud-based infrastructure. 

The results show that real-time candidate search is achievable on mid-range mobile devices. Although generative analysis requires more time, it remains practical for targeted use cases. 

By operating entirely offline, the system ensures strong data privacy and addresses key concerns related to data security and regulatory compliance. Overall, this work highlights the potential of on-device AI systems in enabling privacy-aware recruitment solutions. 

**6\. Acknowledgments** 

**References** 

​​1.Pendyala VS, Thakur NB, Agarwal R. Explainable Use of Foundation Models for Job Hiring. Electronics (Switzerland). 2025 Jul 1;14(14). doi:10.3390/electronics14142787 

​2.Babayev S, Fuad S. BEYOND AUTOMATION IN ADVANCING HUMAN RESOURCES MANAGEMENT THROUGH AI AND ETHICS. Universum:Technical sciences. 2025 Apr 28;4(133). doi:10.32743/unitech.2025.133.4.19807 

​3.Oladele OK. AI in Human Resources: Bias-Free Recruitment, Employee Engagement, and Workforce Planning. 2025. 

​4.Khan NM, Bhattacharya P, Xia Y, Cai J, Fang K, Feng H, et al. Scaling Down with Small Language Models: Vision, Application, Opportunities, and Challenges \[Internet\]. 2026. Available from: [https://www.techrxiv.org/doi/full/10.36227/techrxiv.177004226.60393974/v1](https://www.techrxiv.org/doi/full/10.36227/techrxiv.177004226.60393974/v1) doi:10.36227/techrxiv.177004226.60393974/v1 

​5.Xiao J, Huang Q, Chen X, Tian C. Understanding Large Language Models in Your Pockets: Performance Study on COTS Mobile Devices. IEEE Trans Mob Comput. 2026;1–18. doi:10.1109/TMC.2026.3674827 

​6.Li L, Qian S, Lu J, Yuan L, Wang R, Xie Q. Transformer-Lite: High-efficiency Deployment of Large Language Models on Mobile Phone GPUs. 

​7.Marib M. DAAI: Device-Autonomous Artificial Intelligence A Conceptual Framework for Fully Offline, Privacy-First, Personalized AI on Consumer Devices. 

​8.Hua SZ, Lotfi S, Chen IY. Uncertainty Drives Social Bias Changes in Quantized Large Language Models \[Internet\]. 2026 Feb 5. Available from: [http://arxiv.org/abs/2602.06181](http://arxiv.org/abs/2602.06181) 

​9.Tang P, Liu J, Hou X, Pu Y, Wang J, Heng PA, et al. MoE-APEX: An Efficient MoE Inference System with Adaptive Precision Expert Offloading. In: Proceedings of the 31st ACM International Conference on Architectural Support for Programming Languages and Operating Systems, Volume 2 \[Internet\]. New York, NY, USA: ACM; 2026. p. 1185–200. Available from: [https://dl.acm.org/doi/10.1145/3779212.3790187](https://dl.acm.org/doi/10.1145/3779212.3790187) doi:10.1145/3779212.3790187 

​10.Perez F, Ribeiro I. Ignore Previous Prompt: Attack Techniques For Language Models \[Internet\]. 2022 Nov 17. Available from: [http://arxiv.org/abs/2211.09527](http://arxiv.org/abs/2211.09527) 

​11.I (Legislative acts) REGULATIONS REGULATION (EU) 2016/679 OF THE EUROPEAN PARLIAMENT AND OF THE COUNCIL of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (General Data Protection Regulation) (Text with EEA relevance). 

​12.Yan B, Li K, Xu M, Dong Y, Zhang Y, Ren Z, et al. On Protecting the Data Privacy of Large Language Models (LLMs): A Survey \[Internet\]. 2024 Mar 14. Available from: [http://arxiv.org/abs/2403.05156](http://arxiv.org/abs/2403.05156) 

​13.Tabassi E. Artificial Intelligence Risk Management Framework (AI RMF 1.0) \[Internet\]. 2023 Jan. Available from: [http://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf](http://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf) doi:10.6028/NIST.AI.100-1 

​14.Sibai N, Ahmed Y, Sibaee S, AlHalawani S, Ammar A, Boulila W. The Path Ahead for Agentic AI: Challenges and Opportunities \[Internet\]. 2026 Jan 6. Available from: [http://arxiv.org/abs/2601.02749](http://arxiv.org/abs/2601.02749) 

​15.Jhon M, Jeon EK, Kim DK, Jeon IS, Park SJ, Kim JM, et al. Development and validation of an on-device multimodal system for 2 depression screening (V3-Gemma): a diagnostic model development study \[Internet\]. Available from: [https://ssrn.com/abstract=6034165](https://ssrn.com/abstract=6034165) 

​16.Maliakkal R, Makin Y, Rath P, Jain R, Sadhoo A. Large Language Model Deployment on Resource-Constrained Edge Devices: A Practitioner’s Survey. In: 2026 IEEE 16th Annual Computing and Communication Workshop and Conference (CCWC). 2026. p. 187–95. doi:10.1109/CCWC67433.2026.11393769 

​17.Abstreiter M, Tarkoma S, Morabito R. Sometimes Painful but Promising: Feasibility and Trade-Offs of On-Device Language Model Inference. ACM Transactions on Embedded Computing Systems. 2026 Mar 31. doi:10.1145/3788870 

​18.Gu Y, Kadekodi R, Nguyen H, Kamahori K, Liu Y, Kasikci B. ConsumerBench: Benchmarking Generative AI Applications on End-User Devices \[Internet\]. 2025 Jun 21. Available from: [http://arxiv.org/abs/2506.17538](http://arxiv.org/abs/2506.17538) 

​19.Kim MK, Yoo TA, Chung JB. Toward Sustainable AI: A Scoping Review of Carbon Footprint and Environmental Impacts Across Training and Inference Stages. IEEE Access. 2026. doi:10.1109/ACCESS.2026.3659894 

​20.Oliveira AP, Carraquico T, Martinez-Perez C. Beyond Efficiency: A Systematic Review of Energy Consumption and Carbon Footprint Across the AI Lifecycle. Sustainability (Switzerland). Multidisciplinary Digital Publishing Institute (MDPI); 2026. doi:10.3390/su18031359 

​21.Karpukhin V, Oğuz B, Min S, Lewis P, Wu L, Edunov S, et al. Dense Passage Retrieval for Open-Domain Question Answering \[Internet\]. 2020 Sep 30. Available from: [http://arxiv.org/abs/2004.04906](http://arxiv.org/abs/2004.04906) 

​22.Lewis P, Perez E, Piktus A, Petroni F, Karpukhin V, Goyal N, et al. Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks \[Internet\]. Available from: [https://github.com/huggingface/transformers/blob/master/](https://github.com/huggingface/transformers/blob/master/) 

​23.Mehrabi N, Morstatter F, Saxena N, Lerman K, Galstyan A. A Survey on Bias and Fairness in Machine Learning \[Internet\]. 2022 Jan 25. Available from: [http://arxiv.org/abs/1908.09635](http://arxiv.org/abs/1908.09635) 

​ ​