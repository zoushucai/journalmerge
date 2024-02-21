import shutil
import filecmp
import os
import subprocess


def compare_and_copy(file1: str, file2: str) -> None:
    """
    Compare two files and copy file1 to file2 if they are different.
    Args:
        file1 (str): Path to the first file.
        file2 (str): Path to the second file.
    return:
        None
    """
    if not os.path.exists(file1):
        print(f"Error: {file1} does not exist.")
        return

    if not os.path.exists(file2):
        print(f"{file2} does not exist, copying {file1} to {file2}.")
        shutil.copy(file1, file2)
        print("File copied successfully.")
        return

    if filecmp.cmp(file1, file2):
        print("Files are identical.")
    else:
        print("Files are different. Copying...")
        shutil.copy(file1, file2)
        print("File copied successfully.")


def run_rscript(script_path: str) -> None:
    """
    Run an R script using subprocess.run.
    Args:
        script_path (str): Path to the R script.
    return:
        None
    """
    try:
        subprocess.run(["Rscript", script_path], check=True)
        print("R script executed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    current_directory = os.getcwd()

    # Run R script
    r_script_path = "./combine_journal_lists.R"
    run_rscript(r_script_path)

    # Compare and copy again
    new_file2 = os.path.join(current_directory, "data_new.ts")
    existing_file2 = os.path.join(current_directory, "data.ts")
    compare_and_copy(new_file2, existing_file2)
