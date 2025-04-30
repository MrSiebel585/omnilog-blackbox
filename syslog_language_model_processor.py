import tailer
import configparser
import argparse
import logging
import os
from transformers import pipeline

def load_config(config_path):
    config = configparser.ConfigParser()
    if os.path.exists(config_path):
        config.read(config_path)
    else:
        logging.warning(f"Config file {config_path} not found. Using defaults.")
    return config

def get_config_value(config, section, option, default):
    try:
        return config.get(section, option)
    except (configparser.NoSectionError, configparser.NoOptionError):
        return default

def setup_logger():
    logger = logging.getLogger('syslog_processor')
    logger.setLevel(logging.INFO)
    ch = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger

def simplify_log(nlp, log_line):
    try:
        simplified_text = nlp(log_line, max_length=50, clean_up_tokenization_spaces=True)
        return simplified_text[0]['generated_text']
    except Exception as e:
        logger.error(f"Error simplifying log line: {e}")
        return None

def process_new_log_lines(log_path, nlp, output_file=None):
    if output_file:
        out_fh = open(output_file, 'a')
    else:
        out_fh = None

    for line in tailer.follow(open(log_path)):
        simplified_log = simplify_log(nlp, line)
        if simplified_log:
            if out_fh:
                out_fh.write(simplified_log + "\n")
                out_fh.flush()
            else:
                print(simplified_log)

if __name__ == "__main__":
    logger = setup_logger()

    parser = argparse.ArgumentParser(description='Syslog Processor Service')
    parser.add_argument('--config', type=str, default='/etc/syslog_processor/config.ini',
                        help='Path to configuration file')
    parser.add_argument('--logfile', type=str, help='Path to syslog file to monitor')
    parser.add_argument('--model', type=str, help='Hugging Face model to use')
    parser.add_argument('--output', type=str, help='Output file for simplified logs')

    args = parser.parse_args()

    config = load_config(args.config)

    log_path = args.logfile or get_config_value(config, 'Settings', 'logfile', '/var/log/syslog')
    model_name = args.model or get_config_value(config, 'Settings', 'model', 'https://huggingface.co/EleutherAI/gpt-neo-125m')
    output_file = args.output or get_config_value(config, 'Settings', 'output', None)

    logger.info(f"Using log file: {log_path}")
    logger.info(f"Using model: {model_name}")
    if output_file:
        logger.info(f"Outputting simplified logs to: {output_file}")
    else:
        logger.info("Outputting simplified logs to console")

    nlp = pipeline("text2text-generation", model=model_name)

    try:
        process_new_log_lines(log_path, nlp, output_file)
    except KeyboardInterrupt:
        logger.info("Syslog Processor stopped by user")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
