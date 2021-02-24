#!groovy
/**
 ***************************************************************************************************
 * Copyright (C) 2020 Faurecia Clarion Electronics Europe SAS
 *
 * @brief Jenkins pipeline for nightly builds
 *
 ***************************************************************************************************
 */
library 'CommonPipeline'
import groovy.transform.Field

@Field final gitCredentialsId = 'a14ed9ea-e410-4e89-a071-710b3e41d034'
@Field final manifestGitRepoUrl = 'ssh://gerrit.pfa.tds/rapide/manifest'
@Field final manifestGitRepoBranch = 'rapide10-master'
@Field final buildType = 'eng'
@Field final buildStatusWatchers = ''

@Field final dockerRegistry = "registry.pfa.tds:5000"
@Field final dockerRegistryCredentials = '91fe21bb-00cf-4f9a-b796-3860e2a64909'

@Field bootloaderArtifacts = ['$targetOut/bootloader/tcc803x_fwdn32.rom',
                              '$targetOut/bootloader/tcc803x_snor_boot.rom',
                              '$targetOut/bootloader/sd_data.fai',
                              '$targetOut/staging-host/usr/bin/tcc_fwdn_plus']

def nativeUnitTests = node() {
    checkout scm
    readYaml(file: 'res/nativeUnitTests.yml')
}

@Field def devicesStatus = [:] // Track status of each target
try {
    def chrootPes77ABuilder = pulsarBuilder(target:"pulsar_rapide", variant: "pes77A")
    def a7Pes77ABuilder = pulsarBuilder(target:"pulsar_a7", variant: "pes77A")

    def chrootPes8200Builder = pulsarBuilder(target:"pulsar_rapide", variant: "pes8200")
    def a7Pes8200Builder = pulsarBuilder(target:"pulsar_a7", variant: "pes8200")

    parallel \
        makeTask('bootloader-pes77A', 'rapide-pulsar-armv8', 'bootloader.xml') {
            def blPes77AEngBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes77A_eng")
            def blPes77AEngBuild = blPes77AEngBuilder.updateConfig().build()
            blPes77AEngBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                              artifactsPath: "pes77A-$buildType/bootloader-eng")

            def blPes77AProdBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes77A_prod")
            def blPes77AProdBuild = blPes77AProdBuilder.updateConfig().build()
            blPes77AProdBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                               artifactsPath: "pes77A-$buildType/bootloader-prod")
        } + makeTask('a7-pes77A', 'rapide-pulsar-armv7', 'a7.xml') {
            def a7Pes77ABuild = a7Pes77ABuilder.updateConfig().build()
            a7Pes77ABuild.stash(['$targetOut/a7s_dtb.img', '$targetOut/a7s_boot.img',
                                 '$targetOut/a7s_root.img'])
        } + makeTask('pulsar-pes77A', 'rapide-pulsar-armv8', 'pulsar.xml') {
            def chrootPes77ABuild = chrootPes77ABuilder.updateConfig().build()
            chrootPes77ABuild.stash(['$targetOut/pulsar_rapide-pes77A.tar.gz'])
        } + makeTask("pes77A", 'rapide-android', 'default.xml') {
            def nproc = nproc()
            def kernelConfig = "${buildType}_kernel_config"
            updateKernelConfig(product: "$device-$buildType", kernelPath: 'kernel',
                               kernelConfigPath: "device/parrot/$device/$kernelConfig")
            sh """#!/bin/bash -e
source ./build/envsetup.sh
lunch $device-$buildType
cd kernel
make ARCH=arm KCONFIG_CONFIG=../device/parrot/pes77A/$kernelConfig -j $nproc -l $nproc
"""
            def pulsarArchive = chrootPes77ABuilder.unstash() + '/pulsar_rapide-pes77A.tar.gz'
            def a7ImgPath = a7Pes77ABuilder.unstash()
            withEnv(["BOARD_PREBUILT_PULSAR_ARCHIVE=$pulsarArchive",
                     "BOARD_PREBUILT_A7S_PATH=$a7ImgPath"]) {
                buildAosp target: "$device-$buildType", systemImage: true, ota: true,
                        extraArtifacts: ['$targetOut/fastboot.sh',
                                         'out/host/linux-x86/bin/fastboot',
                                         'device/parrot/pes77A/HOWTO_FLASH_ARTIFACTS.md']
            }
            aospBuildVsdk target: "$device-$buildType"
            detectCustomizedKernel(device)
            aospVerifyPrivappPermission "$device-$buildType"
            aospVerifySelinux device
            aospRunJavaUnitTests "$device-$buildType"
        }

    parallel \
        makeTask('bootloader-pes77evb', 'rapide-pulsar-armv8', 'bootloader.xml') {
            def blPes77evbEngBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes77evb_eng")
            def blPes77evbEngBuild = blPes77evbEngBuilder.updateConfig().build()
            blPes77evbEngBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                                artifactsPath: "pes77evb-$buildType/bootloader-eng")

            def blPes77evbProdBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes77evb_prod")
            def blPes77evbProdBuild = blPes77evbProdBuilder.updateConfig().build()
            blPes77evbProdBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                                 artifactsPath: "pes77evb-$buildType/bootloader-prod")

        } + makeTask("pes77evb", 'rapide-android', 'default.xml') {
            def nproc = nproc()
            updateKernelConfig(product: "$device-$buildType", kernelPath: 'kernel',
                               kernelConfigPath: "device/parrot/$device/kernel_config")
            sh """#!/bin/bash -e
source ./build/envsetup.sh
lunch $device-$buildType
cd kernel
make ARCH=arm KCONFIG_CONFIG=../device/parrot/pes77evb/kernel_config -j $nproc -l $nproc
"""
            /* For pulsar, pes77evb uses the same config and images as pes77A */
            def pulsarArchive = chrootPes77ABuilder.unstash() + '/pulsar_rapide-pes77A.tar.gz'
            def a7ImgPath = a7Pes77ABuilder.unstash()
            withEnv(["BOARD_PREBUILT_PULSAR_ARCHIVE=$pulsarArchive",
                     "BOARD_PREBUILT_A7S_PATH=$a7ImgPath"]) {
                buildAosp target: "$device-$buildType", systemImage: true, ota: true,
                          extraArtifacts: ['$targetOut/fastboot.sh',
                                           'out/host/linux-x86/bin/fastboot',
                                           'device/parrot/pes77evb/HOWTO_FLASH_ARTIFACTS.md']
            }
            detectCustomizedKernel(device)
            aospVerifyPrivappPermission "$device-$buildType"
            aospVerifySelinux device
            aospRunJavaUnitTests "$device-$buildType"
        }

    parallel \
        makeTask('bootloader-pes8200', 'rapide-pulsar-armv8', 'bootloader.xml') {
            def blPes8200EngBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes8200_eng")
            def blPes8200EngBuild = blPes8200EngBuilder.updateConfig().build()
            blPes8200EngBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                               artifactsPath: "pes8200-$buildType/bootloader-eng")

            def blPes8200ProdBuilder = pulsarBuilder(target:"pulsar_tccboot", variant: "pes8200_prod")
            def blPes8200ProdBuild = blPes8200ProdBuilder.updateConfig().build()
            blPes8200ProdBuild.archiveArtifacts(artifacts: bootloaderArtifacts,
                                                artifactsPath: "pes8200-$buildType/bootloader-prod")
        } + makeTask('a7-pes8200', 'rapide-pulsar-armv7', 'a7.xml') {
            def a7Pes8200Build = a7Pes8200Builder.updateConfig().build()
            a7Pes8200Build.stash(['$targetOut/a7s_dtb.img', '$targetOut/a7s_boot.img',
                                  '$targetOut/a7s_root.img'])
        } + makeTask('pulsar-pes8200', 'rapide-pulsar-armv8', 'pulsar.xml') {
            def chrootPes8200Build = chrootPes8200Builder.updateConfig().build()
            chrootPes8200Build.stash(['$targetOut/pulsar_rapide-pes8200.tar.gz'])
        } + makeTask("pes8200", 'rapide-android', 'default.xml') {
            def nproc = nproc()
            def kernelConfig = "${buildType}_kernel_config"
            updateKernelConfig(product: "$device-$buildType", kernelPath: 'kernel',
                               kernelConfigPath: "device/parrot/$device/$kernelConfig")
            sh """#!/bin/bash -e
source ./build/envsetup.sh
lunch $device-$buildType
cd kernel
make ARCH=arm KCONFIG_CONFIG=../device/parrot/$device/$kernelConfig -j $nproc -l $nproc
"""
            def pulsarArchive = chrootPes8200Builder.unstash() + '/pulsar_rapide-pes8200.tar.gz'
            def a7ImgPath = a7Pes8200Builder.unstash()
            withEnv(["BOARD_PREBUILT_PULSAR_ARCHIVE=$pulsarArchive",
                     "BOARD_PREBUILT_A7S_PATH=$a7ImgPath"]) {
                buildAosp target: "$device-$buildType", systemImage: true, ota: true,
                          extraArtifacts: ['$targetOut/fastboot.sh',
                                           'out/host/linux-x86/bin/fastboot',
                                           'device/parrot/pes8200/HOWTO_FLASH_ARTIFACTS.md']
            }
            detectCustomizedKernel(device)
            aospVerifyPrivappPermission "$device-$buildType"
            aospVerifySelinux device
            aospRunJavaUnitTests "$device-$buildType"
        }

    parallel \
        makeTask("rapide_emu_x86_64", 'rapide-android', 'default.xml') {
            buildAosp target: "$device-eng", systemImage: true
            aospBuildVsdk target: "$device-$buildType"
        }
parallel \
        makeTask("androidx", 'rapide-android', 'default.xml', '-all,-notdefault,name:aosp/prebuilts/sdk') {
            dir('prebuilts/sdk/current/androidx') {
                withCredentials([usernamePassword(credentialsId: artifactoryCredentialsId, usernameVariable: 'USER', passwordVariable: 'PASSWD')]) {
                    sh './gradlew -Partifactory_user=$USER -Partifactory_password=$PASSWD artifactoryPublish'
                }
            }
        }
    parallel \
        makeTask("native-unit-tests", 'rapide-docker', 'default.xml') {
            withAndroidEmulator(image: 'registry.pfa.tds:5000/rapide/emulator:latest-29') { emulator ->
                def androidImage = docker.image('registry.pfa.tds:5000/rapide/android:latest')
                androidImage.pull()
                androidImage.inside() {
                    def nproc = nproc()
                    def allTests = nativeUnitTests.join(' ')
                    buildAosp.lunch target: "rapide_emu_x86_64-$buildType",
                                    script: "make $allTests -j$nproc -l$nproc"

                    emulator.waitForBoot()

                    sh "adb push out/target/product/generic_x86_64/system/lib64 /data/local/tmp"
                    sh "adb push out/target/product/generic_x86_64/vendor/lib64 /data/local/tmp"
                    sh "adb push out/target/product/generic_x86_64/testcases /data/local/tmp"

                    dir('test-reports') {
                        dir('64') {
                            nativeUnitTests.each { test ->
                                runGoogleTest command: "LD_LIBRARY_PATH=/system/lib64/vndk-29:/data/local/tmp/lib64 /data/local/tmp/testcases/${test}/x86_64/${test}"
                            }
                        }
                    }
                    stage("Publish Google Test reports") {
                        publishGoogleTest("test-reports")
                    }
                } // docker.image(rapide/android).inside()
            }// withAndroidEmulator
        }
} catch (e) {
    String subject = "FAILURE : Job '$JOB_NAME' / Build '$BUILD_NUMBER'"
    int padding = devicesStatus.collect { key, value -> key }.max { it.size() }.size() + 1
    String body = "Devices:\n" +
                  devicesStatus.collect { device, status ->
                      "   ${"$device:".padRight(padding)} $status\n"
                  }.join('') +
                  "Check console output at ${BUILD_URL}"
    emailext(
        subject: subject,
        body: body,
        recipientProviders: [[$class: 'RequesterRecipientProvider']],
        to: buildStatusWatchers
    )
    throw e
}

//TODO SRN-2348 Update the generic step in CommonPipeline instead of this specific function
def updateKernelConfig(Map config) {
    def absKernelConfigPath = sh(returnStdout: true, script: "pwd").trim() + "/$config.kernelConfigPath"
    echo "absKernelConfigPath $absKernelConfigPath"
    sh "make -C ${config.kernelPath} olddefconfig ARCH=arm KCONFIG_CONFIG=$absKernelConfigPath"

    if (sh(returnStdout: true, script: "git -C \$(dirname $absKernelConfigPath) diff \$(basename $absKernelConfigPath)")) {
        unstable 'Kernel config updated automatically'
        createSummary icon: 'warning', id: '1', text: "${config.product}: Kernel config has been" +
                " updated automatically for this build only, please update kernel config" +
                " manually, build is labeled unstable"
        addBadge icon: 'warning.png', text: "${config.product}: Kernel config auto update"
    }
}

def archiveRepoManifest(filename) {
    sh "repo manifest -r -o $filename"
    echo filename
    sh "cat $filename"
    archiveArtifacts artifacts: "$filename", fingerprint: true
}

def detectCustomizedKernel(device, name='os/kernel/tcc', osBranch='fce_android_tcc_sr1_v4.14.y') {
    def path = sh(returnStdout: true, script: "repo forall $name -c 'echo \$REPO_PATH'").trim()
    def rapideBranch = sh(returnStdout:true, script: "repo forall $name -c 'echo \$REPO_RREV'").trim()
    def remote = sh(returnStdout:true, script: "repo forall $name -c 'echo \$REPO_REMOTE'").trim()
    sshagent(credentials: [gitCredentialsId]) {
        sh "git -C $path fetch $remote $osBranch"
    }
    if (sh(returnStdout: true, script: "git -C $path diff $remote/$osBranch..$remote/$rapideBranch")) {
        def diffFiles = sh returnStdout: true, script: "git -C '$path' --no-pager diff --numstat $remote/$osBranch..$remote/$rapideBranch"
        createSummary icon: 'warning', id: '1',
                      text: "$device: in project <code>$name</code><br>" +
                            "Rapide branch <code>$rapideBranch</code> has diverged from upstream OS branch <code>$osBranch</code><br>" +
                            "This can only be a temporary fix: changes must be made to ensure Rapide gets back to using same code as upstream.<br>" +
                            "Files(s) that differ :<br>" +
                            "<pre>$diffFiles</pre>"
        addBadge icon: 'warning.png', text: "$device: Kernel is customized"
    }
}

def makeTask(device, label, manifest = 'default.xml', group = '', Closure c) {
    devicesStatus[device] = '❔ NOT_BUILT'
    [ "$device" : {
        try {
            node(label) {
                timeout(time: 10, unit: 'HOURS') { ansiColor('xterm') { timestamps {
                    stage("Checkout $device") {
                        repoCheckout url: manifestGitRepoUrl,
                                     credentialsIds: [gitCredentialsId],
                                     branch: manifestGitRepoBranch,
                                     manifest: "$manifest",
                                     group: group,
                                     useRepoPlugin: false

                        archiveRepoManifest "$device-$manifest"
                    }
                    stage("Build $device") {
                        c.delegate = [device: device]
                        c()
                    }
                }}} // timeout() { ansiColor() { timestamps {
            }
            devicesStatus[device] = '✅ SUCCESS'
        } catch (e) {
            devicesStatus[device] = '❎ FAILED'
            throw e
        }
    }]
}
