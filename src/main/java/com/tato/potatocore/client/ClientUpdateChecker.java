package com.tato.potatocore.client;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.tato.potatocore.PotatoCore;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraftforge.fml.ModList;\nimport net.minecraftforge.fml.loading.FMLPaths;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class ClientUpdateChecker {
    private static final String RELEASE_API = "https://api.github.com/repos/wtffidy/PotatoCore/releases/latest";
    private static final ExecutorService EXECUTOR = Executors.newSingleThreadExecutor(runnable -> {
        Thread thread = new Thread(runnable, "PotatoCore-Updater");
        thread.setDaemon(true);
        return thread;
    });
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    private static volatile String pendingNotice;

    private ClientUpdateChecker() {
    }

    public static void checkForUpdates() {
        if (!PotatoCoreConfig.AUTO_UPDATE_ENABLED.get()) {
            return;
        }

        EXECUTOR.execute(ClientUpdateChecker::checkForUpdatesInternal);
    }

    public static String consumeNotice() {
        String notice = pendingNotice;
        if (notice != null) {
            pendingNotice = null;
        }

        return notice;
    }

    private static void checkForUpdatesInternal() {
        try {
            String currentVersion = getCurrentVersion();
            if (currentVersion == null) {
                PotatoCore.LOGGER.debug("Skipping automatic update check because the mod is running from a development directory.");
                return;
            }

            HttpRequest request = HttpRequest.newBuilder(URI.create(RELEASE_API))
                    .timeout(Duration.ofSeconds(20))
                    .header("Accept", "application/vnd.github+json")
                    .header("X-GitHub-Api-Version", "2022-11-28")
                    .header("User-Agent", "PotatoCore-Updater")
                    .GET()
                    .build();

            HttpResponse<String> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 404) {
                PotatoCore.LOGGER.info("No PotatoCore release has been published yet; automatic updates will retry next launch.");
                return;
            }

            if (response.statusCode() != 200) {
                PotatoCore.LOGGER.warn("PotatoCore update check failed with HTTP status {}.", response.statusCode());
                return;
            }

            JsonObject release = JsonParser.parseString(response.body()).getAsJsonObject();
            String latestVersion = getString(release, "tag_name");
            if (latestVersion == null || compareVersions(latestVersion, currentVersion) <= 0) {
                PotatoCore.LOGGER.debug("PotatoCore is up to date ({}).", currentVersion);
                return;
            }

            JsonArray assets = release.getAsJsonArray("assets");
            JsonObject jarAsset = findJarAsset(assets);
            if (jarAsset == null) {
                PotatoCore.LOGGER.warn("PotatoCore release {} does not contain a PotatoCore JAR asset.", latestVersion);
                return;
            }

            String assetName = getString(jarAsset, "name");
            String downloadUrl = getString(jarAsset, "browser_download_url");
            String digest = getString(jarAsset, "digest");
            if (!isSafeAssetName(assetName) || !isTrustedDownloadUrl(downloadUrl)) {
                PotatoCore.LOGGER.warn("PotatoCore release {} contains an invalid download asset; update skipped.", latestVersion);
                return;
            }

            Path currentJar = getInstalledJar();
            if (currentJar == null) {
                PotatoCore.LOGGER.warn("Could not locate the installed PotatoCore JAR. Automatic update is unavailable in this environment.");
                return;
            }

            Path modsDirectory = FMLPaths.MODSDIR.get().toAbsolutePath().normalize();
            Path targetJar = modsDirectory.resolve(assetName).normalize();
            if (!targetJar.getParent().equals(modsDirectory)) {
                PotatoCore.LOGGER.warn("PotatoCore update target escaped the mods directory; update skipped.");
                return;
            }

            Path updateDirectory = FMLPaths.GAMEDIR.get().resolve("potatocore-update").toAbsolutePath().normalize();
            Files.createDirectories(updateDirectory);
            Path downloadPath = updateDirectory.resolve(assetName);
            Path partialPath = updateDirectory.resolve(assetName + ".part");

            downloadAsset(downloadUrl, partialPath);
            verifyDownloadedJar(partialPath, digest);
            Files.move(partialPath, downloadPath, StandardCopyOption.REPLACE_EXISTING);

            if (!scheduleInstall(downloadPath, targetJar, currentJar, updateDirectory)) {
                PotatoCore.LOGGER.warn("PotatoCore {} was downloaded but could not schedule installation. The JAR is saved at {}.", latestVersion, downloadPath);
                pendingNotice = "PotatoCore " + latestVersion + " downloaded, but could not schedule installation. See the game log.";
                return;
            }

            PotatoCore.LOGGER.info("PotatoCore {} has been downloaded and is ready to install after Minecraft closes.", latestVersion);
            pendingNotice = "PotatoCore " + latestVersion + " downloaded. Close Minecraft to finish the update; it will be installed for your next launch.";
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            PotatoCore.LOGGER.warn("PotatoCore update check was interrupted.");
        } catch (Exception exception) {
            PotatoCore.LOGGER.warn("PotatoCore automatic update check failed: {}", exception.getMessage());
            PotatoCore.LOGGER.debug("PotatoCore updater exception", exception);
        }
    }

    private static String getCurrentVersion() {
        Package modPackage = PotatoCore.class.getPackage();
        return modPackage == null ? null : modPackage.getImplementationVersion();
    }

    private static JsonObject findJarAsset(JsonArray assets) {
        if (assets == null) {
            return null;
        }

        for (JsonElement element : assets) {
            if (!element.isJsonObject()) {
                continue;
            }

            JsonObject asset = element.getAsJsonObject();
            String name = getString(asset, "name");
            if (isSafeAssetName(name)) {
                return asset;
            }
        }

        return null;
    }

    private static String getString(JsonObject object, String property) {
        JsonElement element = object.get(property);
        return element == null || element.isJsonNull() ? null : element.getAsString();
    }

    private static boolean isSafeAssetName(String name) {
        return name != null
                && name.matches("(?i)PotatoCore-[0-9][A-Za-z0-9.+-]*\\.jar")
                && Path.of(name).getFileName().toString().equals(name);
    }

    private static boolean isTrustedDownloadUrl(String downloadUrl) {
        if (downloadUrl == null) {
            return false;
        }

        try {
            URI uri = URI.create(downloadUrl);
            return "https".equalsIgnoreCase(uri.getScheme())
                    && "github.com".equalsIgnoreCase(uri.getHost());
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private static Path getInstalledJar() {
        try {
            URI location = PotatoCore.class.getProtectionDomain().getCodeSource().getLocation().toURI();
            Path jarPath = Path.of(location).toAbsolutePath().normalize();
            Path modsDirectory = FMLPaths.MODSDIR.get().toAbsolutePath().normalize();

            if (!Files.isRegularFile(jarPath)
                    || !jarPath.getParent().equals(modsDirectory)
                    || !jarPath.getFileName().toString().toLowerCase().startsWith("potatocore")
                    || !jarPath.getFileName().toString().toLowerCase().endsWith(".jar")) {
                return null;
            }

            return jarPath;
        } catch (Exception exception) {
            PotatoCore.LOGGER.debug("Could not resolve the installed PotatoCore JAR path.", exception);
            return null;
        }
    }

    private static void downloadAsset(String downloadUrl, Path destination) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder(URI.create(downloadUrl))
                .timeout(Duration.ofMinutes(2))
                .header("User-Agent", "PotatoCore-Updater")
                .GET()
                .build();

        HttpResponse<Path> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofFile(destination));
        if (response.statusCode() != 200) {
            Files.deleteIfExists(destination);
            throw new IOException("GitHub asset download returned HTTP " + response.statusCode());
        }
    }

    private static void verifyDownloadedJar(Path jarPath, String expectedDigest) throws IOException, NoSuchAlgorithmException {
        try (InputStream inputStream = Files.newInputStream(jarPath)) {
            byte[] signature = inputStream.readNBytes(4);
            if (signature.length != 4
                    || signature[0] != 0x50
                    || signature[1] != 0x4B
                    || signature[2] != 0x03
                    || signature[3] != 0x04) {
                throw new IOException("Downloaded update is not a valid JAR archive.");
            }
        }

        if (expectedDigest != null && expectedDigest.startsWith("sha256:")) {
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            try (InputStream inputStream = Files.newInputStream(jarPath)) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    sha256.update(buffer, 0, bytesRead);
                }
            }

            String actualDigest = HexFormat.of().formatHex(sha256.digest());
            String expectedHash = expectedDigest.substring("sha256:".length());
            if (!actualDigest.equalsIgnoreCase(expectedHash)) {
                throw new IOException("Downloaded update failed its SHA-256 verification.");
            }
        }
    }

    private static boolean scheduleInstall(Path downloadedJar, Path targetJar, Path currentJar, Path updateDirectory) throws IOException {
        if (targetJar.equals(currentJar)) {
            return false;
        }

        Path backupJar = currentJar.resolveSibling(currentJar.getFileName() + ".potatocore-backup");
        long processId = ProcessHandle.current().pid();
        String scriptName = isWindows() ? "install-update.cmd" : "install-update.sh";
        Path scriptPath = updateDirectory.resolve(scriptName);

        String script = isWindows()
                ? createWindowsInstallScript(processId, downloadedJar, targetJar, currentJar, backupJar, scriptPath)
                : createUnixInstallScript(processId, downloadedJar, targetJar, currentJar, backupJar, scriptPath);
        Files.writeString(scriptPath, script);

        ProcessBuilder processBuilder;
        if (isWindows()) {
            processBuilder = new ProcessBuilder("cmd.exe", "/c", "start", "\"\"", "/min", "cmd.exe", "/c", "\"" + scriptPath + "\"");
        } else {
            processBuilder = new ProcessBuilder("sh", "-c", "nohup sh " + shellQuote(scriptPath.toString()) + " >/dev/null 2>&1 &");
        }

        processBuilder.redirectErrorStream(true);
        processBuilder.redirectOutput(ProcessBuilder.Redirect.DISCARD);
        processBuilder.redirectInput(ProcessBuilder.Redirect.DISCARD);
        processBuilder.start();
        return true;
    }

    private static String createWindowsInstallScript(long processId, Path downloadedJar, Path targetJar, Path currentJar, Path backupJar, Path scriptPath) {
        return "@echo off\r\n"
                + "setlocal\r\n"
                + "set \"TARGET_PID=" + processId + "\"\r\n"
                + ":wait_for_game\r\n"
                + "tasklist /FI \"PID eq %TARGET_PID%\" /NH | find \"%TARGET_PID%\" >nul\r\n"
                + "if not errorlevel 1 (\r\n"
                + "  timeout /t 2 /nobreak >nul\r\n"
                + "  goto wait_for_game\r\n"
                + ")\r\n"
                + "if exist " + batchQuote(backupJar) + " del /F /Q " + batchQuote(backupJar) + " >nul 2>&1\r\n"
                + "move /Y " + batchQuote(currentJar) + " " + batchQuote(backupJar) + " >nul\r\n"
                + "if errorlevel 1 exit /b 1\r\n"
                + "move /Y " + batchQuote(downloadedJar) + " " + batchQuote(targetJar) + " >nul\r\n"
                + "if errorlevel 1 (\r\n"
                + "  move /Y " + batchQuote(backupJar) + " " + batchQuote(currentJar) + " >nul\r\n"
                + "  exit /b 1\r\n"
                + ")\r\n"
                + "del /F /Q " + batchQuote(backupJar) + " >nul 2>&1\r\n"
                + "del /F /Q " + batchQuote(scriptPath) + " >nul 2>&1\r\n";
    }

    private static String createUnixInstallScript(long processId, Path downloadedJar, Path targetJar, Path currentJar, Path backupJar, Path scriptPath) {
        return "#!/bin/sh\n"
                + "TARGET_PID=" + processId + "\n"
                + "while kill -0 \"$TARGET_PID\" 2>/dev/null; do sleep 2; done\n"
                + "rm -f " + shellQuote(backupJar.toString()) + "\n"
                + "mv " + shellQuote(currentJar.toString()) + " " + shellQuote(backupJar.toString()) + " || exit 1\n"
                + "if ! mv " + shellQuote(downloadedJar.toString()) + " " + shellQuote(targetJar.toString()) + "; then\n"
                + "  mv " + shellQuote(backupJar.toString()) + " " + shellQuote(currentJar.toString()) + "\n"
                + "  exit 1\n"
                + "fi\n"
                + "rm -f " + shellQuote(backupJar.toString()) + " " + shellQuote(scriptPath.toString()) + "\n";
    }

    private static String batchQuote(Path path) {
        return "\"" + path.toAbsolutePath().toString().replace("%", "%%") + "\"";
    }

    private static String shellQuote(String value) {
        return "'" + value.replace("'", "'\\''") + "'";
    }

    private static boolean isWindows() {
        return System.getProperty("os.name", "").toLowerCase().contains("win");
    }

    private static int compareVersions(String first, String second) {
        int[] firstParts = parseVersion(first);
        int[] secondParts = parseVersion(second);
        for (int index = 0; index < Math.max(firstParts.length, secondParts.length); index++) {
            int firstPart = index < firstParts.length ? firstParts[index] : 0;
            int secondPart = index < secondParts.length ? secondParts[index] : 0;
            if (firstPart != secondPart) {
                return Integer.compare(firstPart, secondPart);
            }
        }

        return 0;
    }

    private static int[] parseVersion(String version) {
        String normalized = version.startsWith("v") || version.startsWith("V") ? version.substring(1) : version;
        normalized = normalized.split("[-+]", 2)[0];
        String[] parts = normalized.split("\\.");
        int[] values = new int[parts.length];

        for (int index = 0; index < parts.length; index++) {
            String numericPart = parts[index].replaceAll("[^0-9].*$", "");
            try {
                values[index] = numericPart.isEmpty() ? 0 : Integer.parseInt(numericPart);
            } catch (NumberFormatException exception) {
                values[index] = 0;
            }
        }

        return values;
    }
}
