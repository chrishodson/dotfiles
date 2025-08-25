import imaplib
import email
import pprint
import csv
from datetime import datetime
import configparser

PRINT = False
batch_size = 1000

def load_config(config_path='config.ini'):
    config = configparser.ConfigParser()
    config.read(config_path)
    username = config.get('EMAIL', 'USERNAME')
    password = config.get('EMAIL', 'PASSWORD')
    return username, password

def fetch_email_counts(username, password, print_headers=False):
  from_count = {}
  try:
    with imaplib.IMAP4_SSL('imap.gmail.com') as M:
      M.login(username, password)
      M.select()
      typ, data = M.search(None, 'ALL')
      message_nums = data[0].split()
      total_message_count = len(message_nums)
      pp = pprint.PrettyPrinter(indent=4)
      for i in range(0, total_message_count, batch_size):
        batch = message_nums[i:i+batch_size]
        percent = ((i+len(batch))/total_message_count)*100
        print(f"Processing emails {i+1}-{min(i+batch_size, total_message_count)} of {total_message_count} ({percent:.2f}%)", end='\r')
        for num in batch:
          try:
            typ, header_data = M.fetch(num, '(BODY.PEEK[HEADER])')
            headers = header_data[0][1].decode("utf-8", errors="replace")
            email_message = email.message_from_string(headers)
            from_nice, from_email = email.utils.parseaddr(email_message['From'])
            if from_email in from_count:
              from_count[from_email] += 1
            else:
              from_count[from_email] = 1
            if print_headers:
              all_items = email_message.items()
              pp.pprint(all_items)
              print('Message %s\n%s\n' % (num, header_data[0][1]))
          except Exception as e:
            print(f"Error processing message {num}: {e}")
      # Print a newline after progress is done
      print()
      M.close()
      M.logout()
  except Exception as e:
    print(f"IMAP error: {e}")
  return from_count

def write_counts_to_csv(counts, filename):
  try:
    with open(filename, 'w', newline='', encoding='utf-8') as f:
      writer = csv.writer(f)
      writer.writerow(['Email', 'Count'])
      for email_addr, count in counts.items():
        writer.writerow([email_addr, count])
  except Exception as e:
    print(f"Error writing CSV: {e}")

if __name__ == "__main__":
  USERNAME, PASSWORD = load_config()
  counts = fetch_email_counts(USERNAME, PASSWORD, PRINT)
  timestamp = datetime.now().strftime('%Y%m%d%H%M')
  output_filename = f'email_counts.{timestamp}.csv'
  write_counts_to_csv(counts, output_filename)