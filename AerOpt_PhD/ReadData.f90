module ReadData
    
    integer :: ne, np, nbf, nbc                             ! Number of elements, Nodes/Points & boundary faces
    integer, dimension(:,:), allocatable :: connecc         ! Connectivity Matrix of Coarse Mesh    
    integer, dimension(:,:), allocatable :: connecf, boundf ! Connectivity & Boundary Matrix of Fine Mesh    
    real, dimension(:,:), allocatable :: coord              ! Coordinates Matrix of Fine Mesh (includes coordinates of coarse mesh)
    real, dimension(:,:), allocatable :: coarse             ! includes element allocation of nodes to coarse triangles and Area Coefficients of each node
    real, dimension(:,:), allocatable :: Coord_CP           ! desired Coordinates of the Control Points
    real, dimension(:,:), allocatable :: Rect               ! Rectangle definition of 'Influence Box'
    
contains
      
    subroutine SubReadData(NoCP, NoDim, InFolder)
    ! Objective: Reads the Mesh data and Control Points Coordinates
    
    ! Variables
    implicit none
    integer :: NoDim, i, NoCP
    character(len=*) :: InFolder
    
    ! Body of ReadData
    open(1, file= InFolder//'/Mesh_fine.txt')
    read(1, 11) ne
    allocate(connecf(ne,NoDim+1))
    read(1, 11) np
    allocate(coord(np,NoDim))
    read(1, 11) nbf
    allocate(boundf(nbf,NoDim))
    do i = 1, ne
        read(1, *) connecf(i,:)
    end do
    do i = 1, np
        read(1, *) coord(i,:)
    end do
    do i = 1, nbf
        read(1, *) boundf(i,:)
    end do 
11  format(1I8)        
    close(1)
    
    allocate(Coord_CP(NoCP,NoDim))
    open(2, file= InFolder//'/Control_Nodes.txt')
    do i = 1, NoCP
        read(2, *) Coord_CP(i,:)
    end do
    close(2)
    
    allocate(Rect(NoCP,NoDim*4))
    open(3, file= InFolder//'/Rectangles.txt')
    do i = 1, NoCP
        read(3, *) Rect(i,:)
    end do
    close(3)
    
    open(4, file= InFolder//'/Mesh_coarse.txt')
    read(4, *) nbc
    allocate(connecc(nbc,NoDim+1))
    allocate(coarse(np-nbf, NoDim+2))
    do i = 1, (np - nbf)
        read(4, *) coarse(i,:)
    end do
    do i = 1, nbc
        read(4, *) connecc(i,:)
    end do
    close(4)
    
    end subroutine SubReadData
    
    subroutine InitSnapshots(filename, istr, coord_temp, boundff, NoDim, OutFolder)
    !Objective: Create Outputfile of each Snapshot as Input for the Pre Processor
    
        ! Variables
        real, dimension(np,NoDim) :: coord_temp
        integer, dimension(nbf,(NoDim+1)) :: boundff
        character(len=*) :: filename, OutFolder
        character(len=*) :: istr
    
        ! Body of InitSnapshots
        open(99, file= OutFolder//'/'//filename//istr//'.dat')
        write(99,*) 1
        write(99,*) 'David Naumann'
        write(99,*) 'NoTrgElem NoNodes NoBound'        
        write(99,*) ne, np, nbf
        write(99,*) 'Connectivities'
        do j = 1, ne
            write(99,*) j, connecf(j,:)
        end do
        write(99,*) 'Coordinates'
        do j = 1, np
            write(99,*) j, coord_temp(j,:)*15.0
        end do
        write(99,*) 'Boundary Faces'
        do j = 1, nbf
            write(99,*) boundff(j,:)
        end do
10      format(2f12.7)        
        close(99)
    
    end subroutine InitSnapshots
    
    subroutine PreProInpFile(filename, istr, InFolder, OutFolder)
    ! Objective: Create the Inputfile for the PreProcessor in Case of the Windows Executable
    
        ! Variables
        character(len=*) :: filename, InFolder, OutFolder
        character(len=*) :: istr
    
        ! Body of PreProInpFile
        open(11, file=InFolder//'/PreprocessingInput.txt')        
        write(11,*) OutFolder, '/', filename, istr, '.dat'  ! Name of Input file
        write(11,*) 'f'                                     ! Hybrid Mesh?
        write(11,*) 1                                       ! Number of Grids
        write(11,*) 0                                       ! Directionality Parameters
        write(11,*) 0                                       ! Visualization Modes
        write(11,*) OutFolder, '/', filename, istr, '.sol'  ! Output File name
        close(11)
    
    end subroutine PreProInpFile
    
    subroutine WriteSolverInpFile(filename, istr, engFMF, hMa, NoIter, newdir, NoNests, defPath, InFolder, OutFolder, SystemType)
    ! Objective: Create Solver Input files
    
        ! Variables
        character(len=*) :: filename, istr, defPath, InFolder, OutFolder, newdir, SystemType
        character(len=:), allocatable :: fname
        character(len=7) :: strEFMF, strMa      ! String for Ma number & Engine Inlet Front Mass Flow Number
        character(len=2) :: strNI               ! String for Number of Iterations
        integer :: fileLength
    
        ! Body of WriteSolverInpFile
        fileLength = len(filename) + len(istr) + 15
        allocate(character(len=fileLength) :: fname)
        fname = InFolder//'/'//filename//istr//'.inp'
        write( strEFMF, '(F7.3)' )  engFMF
        write( strMa, '(F7.3)' )  hMa
        write( strNI, '(I2)' )  NoIter
        
        ! Create Input File for Solver
        open(5, file=fname)
        write(5,*) '&inputVariables'
        write(5,*) 'ivd%numberOfMGIterations = ' ,strNI , ','
        write(5,*) 'ivd%numberOfGridsToUse = 1,'
        write(5,*) 'ivd%viscosityScheme = 1,'
        write(5,*) 'ivd%boundaryTerm = 1,'
        write(5,*) 'ivd%CFLNumber = 1.0,'
        write(5,*) 'ivd%turbulenceCFLFactor = 1.0,'
        write(5,*) 'ivd%alpha = 180,'
        write(5,*) 'ivd%MachNumber = ' ,strMa, ','
        write(5,*) 'ivd%numberOfRelaxationSteps = 1, '
        write(5,*) 'ivd%ReynoldsNumber = 6500000.0,'
        write(5,*) 'ivd%gamma = 1.4,'
        write(5,*) 'ivd%turbulenceModel = 1,'
        write(5,*) 'ivd%multigridScheme = 3,'
        write(5,*) 'ivd%tripFactor = 1.0,'
        write(5,*) 'ivd%dissipationScheme = 2,'
        write(5,*) 'ivd%coarseGriddissipationScheme = 2,'
        write(5,*) 'ivd%secondOrderDissipationFactor = 0.3,'
        write(5,*) 'ivd%fourthOrderDissipationFactor = 0.2,'
        write(5,*) 'ivd%coarseGridDissipationFactor = 0.5,'
        write(5,*) 'ivd%turbulenceSmoothingFactor = 0.0,'
        write(5,*) 'ivd%numberOfRSSteps = 0,'
        write(5,*) 'ivd%tripNodes(1) = 203,'
        write(5,*) 'ivd%tripNodes(2) = 252,'
        write(5,*) 'ivd%residualSmoothingFactor = 0.0,'
        write(5,*) 'ivd%numberOfPSSteps = 0,'
        write(5,*) 'ivd%prolongationSmoothingFactor = 0.0,'
        write(5,*) 'ivd%useMatrixDissipation = .false.,'
        write(5,*) 'ivd%writeToFileInterval = 100,'
        write(5,*) 'ivd%useTimeResidual = .false.,'
        write(5,*) 'ivd%useDissipationWeighting = .false.,'
        write(5,*) 'ivd%normalComponentRelaxation = 1.0,'
        write(5,*) 'ivd%sizeOfSeparationField = 25,'
        write(5,*) 'ivd%numberOfTriperations = 0,'
        write(5,*) 'ivd%enginesFrontMassFlow = ', strEFMF, ','
        write(5,*) 'ivd%maxitt = 50000,'
        write(5,*) '/'
        close(5)
        
        ! Create Read File for Solver
        open(1, file=InFolder//'/SolverInput'//istr//'.txt')
        if (SystemType == 'B') then
            write(1,*) filename, istr, '.inp'    ! Control Filename
            write(1,*) filename, istr, '.sol'    ! Computation Filename
            write(1,*) ''
            write(1,*) filename, istr, '.resp'  ! Result filename
            write(1,*) filename, istr, '.rsd'   ! Residual Filename
        else
            write(1,*) '2DEngInlSim/', newdir, '/', InFolder, '/', filename, istr, '.inp'    ! Control Filename
            write(1,*) '2DEngInlSim/', newdir, '/', InFolder, '/', filename, istr, '.sol'    ! Computation Filename
            write(1,*) ''
            write(1,*) '2DEngInlSim/', newdir, '/', OutFolder, '/', filename, istr, '.resp'  ! Result filename
            write(1,*) '2DEngInlSim/', newdir, '/', OutFolder, '/', filename, istr, '.rsd'   ! Residual Filename
        end if
        close(1)
    
    end subroutine WriteSolverInpFile
    
    subroutine writeBatchFile(filename, istr, path, newdir, SystemType, InFolder, OutFolder)
    
        ! Variables
        character(len=*) :: filename, istr, path, newdir, SystemType, InFolder, OutFolder
        character(len=255) :: Output
    
        ! Body of writeBatchFile
        open(1, file= InFolder//'/batchfile'//istr//'.sh')  
        if (SystemType /= 'B') then
            write(1,*) '#PBS -N ' ,fileName, istr
            write(1,*) '#PBS -q oh'
            write(1,*) '#PBS -l nodes=1:ppn=1'
            write(1,*) '#PBS -l walltime=24:00:00'
            write(1,*) '#PBS -l mem=1gb'
            write(1,*) '#PBS -m bea'
            write(1,*) '#PBS -M 717761@swansea.ac.uk'
            Output = path//' < /eng/cvcluster/egnaumann/2DEngInlSim/'//newdir//'/'//InFolder//'/SolverInput'//istr//'.txt'
            write(1,'(A)') trim(Output)
        else
            write(1,*) '#BSUB -J ' ,fileName, istr
            write(1,*) '#BSUB -o ' ,fileName, istr, '.o'
            write(1,*) '#BSUB -e ' ,fileName, istr, '.e'
            !write(1,*) '#BSUB -q <enter a queue>'
            write(1,*) '#BSUB -n 1'
            write(1,*) '#BSUB -W 24:00'
            write(1,*) 'ssh cf-log-001'
            Output = path//' < /home/david.naumann/2DEngInlSim/'//newdir//'/'//InFolder//'/SolverInput'//istr//'.txt'
            write(1,'(A)') trim(Output)
            write(1,*) 'cd ..'
            write(1,*) 'mv ', InFolder, '/', filename, istr, '.rsd ', OutFolder, '/', filename, istr, '.rsd'
            write(1,*) 'mv ', InFolder, '/', filename, istr, '.resp ', OutFolder, '/', filename, istr, '.resp'
            write(1,*) '#BSUB -n 1'
            !#BSUB -R "span[ptile=12]"
            
        end if
        close(1)
    
    end subroutine writeBatchFile
    
    subroutine createDirectoriesInit(newdir, defPath, InFolder, OutFolder)
    ! Objective: Create Directories from Windows in Linux
    
        ! Variables
        character(len=255) :: currentDir
        character(len=:), allocatable :: Output
        character(len=*) :: newdir, defPath, InFolder, OutFolder
        integer :: strOut
        
        ! Body of createDirectories
        call getcwd(currentDir)
        open(1, file='FileCreateDir.scr')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ', defPath
        write(1,*) 'cd ..'
        write(1,*) 'chmod 777 2DEngInlSim'
        write(1,*) 'cd 2DEngInlSim'
        write(1,*) 'mkdir ', newdir
        write(1,*) 'cd ', newdir
        write(1,*) 'mkdir ', InFolder
        write(1,*) 'mkdir ', OutFolder
        write(1,*) 'cd ..'
        write(1,*) 'cd ..'
        write(1,*) 'chmod 711 2DEngInlSim'
        close(1)
    
    end subroutine createDirectoriesInit
    
    subroutine transferFilesWin(filename, istr, newdir, defPath, InFolder, OutFolder)
    ! Objective: Create Directories from Windows in Linux
    
        ! Variables
        character(len=255) :: currentDir
        character(len=:), allocatable :: Output
        character(len=*) :: filename, istr, newdir, defPath, InFolder, OutFolder
        integer :: strOut
        
        ! Body of createDirectories
        call getcwd(currentDir)
        open(1, file='FileCreateDir.scr')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ', defPath , '/', newdir, '/', InFolder
        
        ! Put Commmands to Transfer Data from Input_Data Folder on Windows to created Input Folder on Cluster
        strOut = len(trim(currentDir)) + 33
        allocate(character(len=strOut) :: Output)
        Output = 'put "'//trim(currentDir)//'/'//InFolder//'/SolverInput'//istr//'.txt"'
        write(1, '(A)') Output       
        deallocate(Output)
                      
        strOut = len(trim(currentDir)) + 22
        allocate(character(len=strOut) :: Output)
        Output = 'put "'//trim(currentDir)//'/'//OutFolder//'/'//filename//istr//'.sol"'
        write(1, '(A)') Output
        deallocate(Output)
        
        strOut = len(trim(currentDir)) + 22
        allocate(character(len=strOut) :: Output)
        Output = 'put "'//trim(currentDir)//'/'//OutFolder//'/'//filename//istr//'.dat"'
        write(1, '(A)') Output
        deallocate(Output)

        strOut = len(trim(currentDir)) + 23
        allocate(character(len=strOut) :: Output)
        Output = 'put "'//trim(currentDir)//'/'//InFolder//'/'//filename//istr//'.inp"'
        write(1, '(A)') Output
        deallocate(Output)
        
        strOut = len(trim(currentDir)) + 25
        allocate(character(len=strOut) :: Output)
        Output = 'put "'//trim(currentDir)//'/'//InFolder//'/batchfile'//istr//'.sh"'
        write(1, '(A)') Output
        close(1)
    
    end subroutine transferFilesWin
    
    subroutine transferFilesLin(filename, istr, newdir, defPath, InFolder, OutFolder)
    ! Objective: Move files from Linux in Linux
    
        ! Variables
        character(len=255) :: currentDir
        character(len=255) :: Output
        character(len=*) :: filename, istr, newdir, defPath, InFolder, OutFolder 
        
        ! Body of createDirectories
        call getcwd(currentDir)
        write(*,*) trim(currentDir)
        open(1, file='FileCreateDir.scr')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ', defPath, '/', newdir, '/', InFolder

        Output = 'mv '//trim(currentDir)//'/'//InFolder//'/SolverInput'//istr//'.txt SolverInput'//istr//'.txt'
        write(1, '(A)') trim(Output)
        
        Output = 'mv '//trim(currentDir)//'/'//OutFolder//'/'//filename//istr//'.sol '//filename//istr//'.sol'
        write(1, '(A)') trim(Output)
        
        Output = 'mv '//trim(currentDir)//'/'//OutFolder//'/'//filename//istr//'.dat '//filename//istr//'.dat'
        write(1, '(A)') trim(Output)
        
        Output = 'mv '//trim(currentDir)//'/'//InFolder//'/'//filename//istr//'.inp '//filename//istr//'.inp'
        write(1, '(A)') trim(Output)
        
        Output = 'mv '//trim(currentDir)//'/'//InFolder//'/batchfile'//istr//'.sh batchfile'//istr//'.sh'
        write(1, '(A)') trim(Output)
        
        close(1)
    
    end subroutine transferFilesLin
    
    subroutine TriggerFile(filename, istr, newdir, defPath, InFolder, SystemType)
    ! Objectives: Triggerfile for Cluster Simulation & Parallelisation
    
        ! Variables
        character(len=*) :: filename, istr, newdir, defPath, InFolder, SystemType
    
        ! Body of TriggerFile
        open(1, file='Trigger.sh')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ', defPath, '/', newdir, '/', InFolder
        
        if (SystemType /= 'B') then
            write(1,*) 'qsub batchfile', istr, '.sh'
        else
            write(1,*) 'bsub < batchfile', istr, '.sh'
        end if
        close(1)
                        
    end subroutine TriggerFile
    
    subroutine TriggerFile2(filename, istr, path)
    ! Objectives: Triggerfile for noncluster Simulation
    
        ! Variables
        character(len=*) :: filename, istr, path
    
        ! Body of TriggerFile
        open(1, file='Trigger.sh')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ..'
        write(1,*) 'cd ..'
        write(1,*) path
        close(1)
                        
    end subroutine TriggerFile2
    
    subroutine CheckSimStatus(newdir, filename, istr, SystemType, defPath, InFolder)
    ! Objectives: writes file that checks for error files and stores response in check.txt file
    
        ! Variables
        character(len=*) :: newdir, filename, istr, SystemType, defPath, InFolder
        character(len=255) :: Output
    
        ! Body of CheckSimStatus
        open(1, file='CheckStatus.scr')
        write(1,*) 'cd '
        write(1,*) 'cd ..'
        write(1,*) 'cd ', defPath, '/', newdir, '/', InFolder      
        write(1,*) '[ -e ', filename, istr, '.e* ] && echo 1 > check.txt || echo 0 > check.txt'
        if (SystemType == 'Q')   then
            write(1,*) 'cd ..'
            write(1,*) 'cd ..'
            Output = 'mv /eng/cvcluster/egnaumann/2DEngInlSim/'//newdir//'/'//InFolder//'/check.txt check.txt'
            write(1, '(A)') trim(Output)
        elseif (SystemType == 'B') then
            write(1,*) 'cd ..'
            write(1,*) 'cd ..'
            Output = 'mv /home/david.naumann/2DEngInlSim/'//newdir//'/'//InFolder//'/check.txt check.txt'
            write(1, '(A)') trim(Output)
        end if
        close(1)
    
    end subroutine CheckSimStatus
    
    subroutine CheckSimStatus2(newdir, defPath, InFolder)
    ! Objectives: Transfers Check file to correct folder
    
        ! Variables
        character(len=*) :: newdir, defPath, InFolder
    
        ! Body of CheckSimStatus
        open(1, file='CheckStatus.scr')
        write(1,*) 'cd '
        write(1,*) 'cd ..'       
        write(1,*) 'cd ', defPath, '/', newdir, '/', InFolder
        write(1,*) 'get check.txt'       
        close(1)
    
    end subroutine CheckSimStatus2
    
end module ReadData