#!/usr/bin/env python3
import os
import matplotlib.pyplot as plt
import numpy as np

def main():
    # Data configuration
    categories = [
        'Raw Vector\nSearch',
        'Static Semantic\nSearch',
        'Keyword\nBaseline',
        'Agentic Query\nReformulation',
        'Generative\nInference (CoT)'
    ]

    # Latencies in milliseconds
    # Pixel 7 Pro values from experiment_data.csv and ARCHITECTURE.md
    # Redmi Note 7 values calculated using 4.5x CPU multiplier and 7.2x LLM bottleneck multiplier
    pixel_latencies = [11.9, 59.3, 535.8, 6694.7, 42400.0]
    redmi_latencies = [53.6, 266.9, 2411.1, 48201.8, 305280.0]

    # Convert to seconds for plotting on log scale
    pixel_seconds = [x / 1000.0 for x in pixel_latencies]
    redmi_seconds = [x / 1000.0 for x in redmi_latencies]

    x = np.arange(len(categories))
    width = 0.35

    # Set style for a clean academic paper appearance matching the architecture diagram
    plt.rcParams['font.family'] = 'sans-serif'
    plt.rcParams['font.sans-serif'] = ['Inter', 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', 'DejaVu Sans']
    
    fig, ax = plt.subplots(figsize=(10, 6.0), dpi=300)

    # Cohesive color palette matching the architecture diagram:
    # Deep Blue (Pixel 7 Pro) vs. Medium/Light Blue (Redmi Note 7)
    pixel_color = '#004B93'  # Deep Blue from Plan/Decide/Act badges
    redmi_color = '#4A90E2'  # Lighter Blue from Query Embedding / Decision nodes

    rects1 = ax.bar(x - width/2, pixel_seconds, width, 
                    label='Google Pixel 7 Pro (Tensor G2)', 
                    color=pixel_color, edgecolor='#00366A', linewidth=0.8, alpha=0.95)
    rects2 = ax.bar(x + width/2, redmi_seconds, width, 
                    label='Redmi Note 7 (Snapdragon 660)', 
                    color=redmi_color, edgecolor='#2D65A8', linewidth=0.8, alpha=0.95)

    # Use logarithmic scale to handle range from milliseconds to hundreds of seconds
    ax.set_yscale('log')
    ax.set_ylim(0.002, 1200.0)  # Start at 2ms, end at 1200 seconds (leaves margin for labels)
    
    # Custom Y-axis ticks and labels
    y_ticks = [0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 10.0, 30.0, 60.0, 180.0, 300.0, 600.0]
    y_tick_labels = ['5 ms', '10 ms', '50 ms', '100 ms', '500 ms', '1 s', '5 s', '10 s', '30 s', '1 min', '3 min', '5 min', '10 min']
    ax.set_yticks(y_ticks)
    ax.set_yticklabels(y_tick_labels, fontsize=10)

    # Labels and Axes configuration (Title removed to match guidelines)
    ax.set_ylabel('Latency (Log Scale)', fontsize=12, fontweight='semibold', labelpad=10)
    ax.set_xticks(x)
    ax.set_xticklabels(categories, fontsize=10.5, fontweight='semibold')
    
    # Elegant legend placement
    ax.legend(loc='upper left', frameon=True, facecolor='#F7F9FA', edgecolor='#D0D5DD', fontsize=10, framealpha=0.9)

    # Gridlines: major and minor
    ax.grid(True, which='both', linestyle=':', linewidth=0.5, color='#B0B5BC', alpha=0.6)
    ax.set_axisbelow(True)

    # Add numeric labels on top of the bars
    def add_labels(rects):
        for rect in rects:
            height = rect.get_height()
            # Determine appropriate label text
            if height < 0.1:
                label_text = f"{height*1000:.0f} ms"
            elif height < 1.0:
                label_text = f"{height*1000:.0f} ms"
            elif height < 60.0:
                label_text = f"{height:.1f} s"
            else:
                minutes = int(height // 60)
                seconds = int(height % 60)
                label_text = f"{minutes}m {seconds}s"
            
            # Position above bar on log scale
            ax.annotate(label_text,
                        xy=(rect.get_x() + rect.get_width() / 2, height),
                        xytext=(0, 4),  # 4 points vertical offset
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8.5, fontweight='bold')

    add_labels(rects1)
    add_labels(rects2)

    # Annotate the 7.2x generative gap specifically
    # Generative Inference is index 4 (X=4)
    # Highlight performance bottleneck with styling matched to diagram buttons
    arrow_props = dict(facecolor='#004B93', edgecolor='none', arrowstyle="-|>", connectionstyle="arc3,rad=-0.2")
    ax.annotate('7.2x performance gap\n(Generative Bottleneck)', 
                xy=(4, (pixel_seconds[4] + redmi_seconds[4])/2), 
                xytext=(2.3, 100.0),
                fontsize=9.5, fontweight='bold', color='#004B93',
                bbox=dict(boxstyle="round,pad=0.4", fc="#EAF2FA", ec="#004B93", lw=1.0),
                arrowprops=arrow_props)

    plt.tight_layout()

    # Ensure directories exist
    os.makedirs('docs', exist_ok=True)
    os.makedirs('screenshots', exist_ok=True)

    # Save high-DPI figures
    plt.savefig('docs/figure2.png', bbox_inches='tight', dpi=300)
    plt.savefig('screenshots/figure2.png', bbox_inches='tight', dpi=300)
    print("Successfully generated docs/figure2.png and screenshots/figure2.png!")

if __name__ == '__main__':
    main()
