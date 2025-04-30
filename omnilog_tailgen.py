import gradio as gr
import subprocess

def generate_report():
    try:
        # Read the contents of the syslog file
        result = subprocess.run(["cat", "/var/log/syslog"], capture_output=True, text=True)
        if result.returncode == 0:
            syslog_content = result.stdout

            # Generate the report using the large language model
            # Replace this with your own code to generate the report based on the syslog content
            report = "This is a sample report generated from the syslog file:\n\n" + syslog_content

            return report
        else:
            return "Failed to read the syslog file."
    except Exception as e:
        return f"An error occurred: {str(e)}"

iface = gr.Interface(fn=generate_report, inputs=None, outputs="text")
iface.launch()
