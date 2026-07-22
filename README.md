# BadAppleCLI

![Design sem nome](https://github.com/user-attachments/assets/329e599e-2284-4d9d-8936-3c166f85334d)
*Original video from [FelipeFMA/BadAppleBash](https://github.com/FelipeFMA/BadAppleBash)*

**This project reproduces the ["Bad Apple!!"](https://youtu.be/9lNZ_Rnr7Jc?si=ROgXrVvdx13oKPM4) video using Bash script, with all graphics rendered in ASCII art.**

## Usage Instructions

This script is available at https://revecoa.skydinse.net/, so the easiest way to run is in online mode:
```bash
bash <(curl -sL https://revecoa.skydinse.net/badapple.sh)
```
Or, if you want to use any options:
```bash
bash <(curl -sL https://revecoa.skydinse.net/badapple.sh) --help
```

---

## Manual Usage

If you want to load the entire script and resources locally, follow these steps:

01. Clone the repository to your local environment:
```bash
git clone https://github.com/Revecoa/BadAppleCLI.git
```

02. Navigate to the project directory:
```bash
cd BadAppleCLI
```

03. Make the `run.sh` script executable:
```bash
chmod +x run.sh
```

04. Run the script:
```bash
./run.sh
```

---

## Server Setup

To host this on your own server, assuming you already have a web server (e.g. Apache, Nginx) set up, follow these steps:

1. Create and navigate to the directory on your web server, where the data for this script should be stored (e.g. `/public/badapple`):
```bash
mkdir -p /path/to/your/public/badapple && cd "$_"
```

2. To clone the repository to this folder, follow the steps from [#Manual Usage](#manual-usage).

3. After cloning, move the repository contents to your intended folder:
```bash
cd /path/to/your/public/badapple
mv BadAppleCLI/* ./
rm -r BadAppleCLI/
```

4. Create the archive `frames.tar.gz` by executing the following command in the same directory where your other resources are stored:
```bash
tar -czf frames.tar.gz frames-ascii/
```

5. Change the value of `URL_RESOURCES` in `run.sh` to match the public base URL where your resources can be found:
```bash
URL="https://example.org/badapple"
sed -i "s|^URL_RESOURCES=.*|URL_RESOURCES=\"$URL\"|g" ./run.sh
```

6. Your script should now be available by running the following command:
```bash
bash <(curl -sL https://example.org/badapple/run.sh) --help
```

---


## Credits

This project is a fork of [FelipeFMA/BadAppleBash](https://github.com/FelipeFMA/BadAppleBash), which is based on [trung-kieen/bad-apple-ascii](https://github.com/trung-kieen/bad-apple-ascii). Special thanks to the original creators for their work!

