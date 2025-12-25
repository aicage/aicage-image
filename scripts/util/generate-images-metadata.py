#!/usr/bin/env python3
import argparse
import io
import os
import tarfile
import tempfile
import urllib.request

import yaml


def load_yaml(path):
    with open(path, "r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return data or {}


def load_config(path):
    data = load_yaml(path)
    base_repo = data.get("AICAGE_IMAGE_BASE_REPOSITORY")
    if not base_repo:
        raise ValueError("AICAGE_IMAGE_BASE_REPOSITORY missing in config.yaml")
    return base_repo


def download_bases_archive(base_repo, dest_dir):
    url = f"https://github.com/{base_repo}/releases/latest/download/bases.tar.gz"
    dest_path = os.path.join(dest_dir, "bases.tar.gz")
    urllib.request.urlretrieve(url, dest_path)
    return dest_path


def unpack_bases_archive(archive_path, dest_dir):
    with tarfile.open(archive_path, "r:gz") as tar:
        tar.extractall(dest_dir)
    bases_dir = os.path.join(dest_dir, "bases")
    if not os.path.isdir(bases_dir):
        raise ValueError(f"Missing bases directory in {archive_path}")
    return bases_dir


def normalize_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return value
    return [value]


def build_base_map(bases_dir):
    base_map = {}
    for alias in sorted(os.listdir(bases_dir)):
        base_dir = os.path.join(bases_dir, alias)
        base_yaml = os.path.join(base_dir, "base.yaml")
        if not os.path.isdir(base_dir) or not os.path.isfile(base_yaml):
            continue
        base_map[alias] = load_yaml(base_yaml)
    return base_map


def build_tool_map(tools_dir, base_map):
    tool_map = {}
    base_aliases = sorted(base_map.keys())
    for tool in sorted(os.listdir(tools_dir)):
        tool_dir = os.path.join(tools_dir, tool)
        tool_yaml = os.path.join(tool_dir, "tool.yaml")
        if not os.path.isdir(tool_dir) or not os.path.isfile(tool_yaml):
            continue
        data = load_yaml(tool_yaml)
        alias_exclude = [
            str(item).lower()
            for item in normalize_list(data.get("base_alias_exclude", []))
        ]
        distro_exclude = [
            str(item).lower()
            for item in normalize_list(data.get("base_distro_exclude", []))
        ]
        valid_aliases = []
        for alias in base_aliases:
            if alias.lower() in alias_exclude:
                continue
            distro = str(base_map[alias].get("base_image_distro", "")).lower()
            if distro_exclude and distro in distro_exclude:
                continue
            valid_aliases.append(alias)
        data["valid_base_aliases"] = valid_aliases
        tool_map[tool] = data
    return tool_map


def write_metadata(output_path, base_map, tool_map):
    payload = {
        "base-alias": base_map,
        "tool": tool_map,
    }
    with open(output_path, "w", encoding="utf-8") as handle:
        yaml.safe_dump(payload, handle, sort_keys=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--tools-dir", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    base_repo = load_config(args.config)
    with tempfile.TemporaryDirectory() as tmpdir:
        archive = download_bases_archive(base_repo, tmpdir)
        bases_dir = unpack_bases_archive(archive, tmpdir)
        base_map = build_base_map(bases_dir)
        tool_map = build_tool_map(args.tools_dir, base_map)

    write_metadata(args.output, base_map, tool_map)


if __name__ == "__main__":
    main()
