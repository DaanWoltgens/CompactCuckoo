INC  = include
INC2 = BGHT-main/include
CXXFLAGS = -O2 -Wall -Wno-sign-compare -I$(INC) -I$(INC2) -Iinclude -DHAVE_CONFIG_H -pedantic
CXX = g++

NVCC = nvcc

SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

ifeq ($(OS),Windows_NT)
	EXECUTABLE = $(BIN_DIR)/main.exe
	NVCCFLAGS = -arch=compute_70 -I$(INC) -I$(INC2)

else
	EXECUTABLE = $(BIN_DIR)/main
	NVCCFLAGS = -arch=sm_75 -O3 -m64 -Xcompiler -Wall -I$(INC) -I$(INC2)

endif

CPP_FILES = $(wildcard $(SRC_DIR)/*.cpp)
CU_FILES  = $(wildcard $(SRC_DIR)/main.cu)


H_FILES   = $(wildcard $(SRC_DIR)/*.h)
CUH_FILES = $(wildcard $(SRC_DIR)/*.cuh)

OBJ_FILES = $(addprefix $(OBJ_DIR)/,$(notdir $(CPP_FILES:.cpp=.o)))
CUO_FILES = $(addprefix $(OBJ_DIR)/,$(notdir $(CU_FILES:.cu=.cu.o)))

OBJS =  $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(notdir $(CPP_FILES)))
OBJS += $(patsubst %.cu,$(OBJ_DIR)/%.cu.o,$(notdir $(CU_FILES)))


all: $(OBJS) $(BIN_DIR) $(EXECUTABLE)

$(TARGET) : $(OBJS)
	$(CXX) $(CXXFLAGS) $(LIB_CUDA) -o $@ $?

$(OBJ_DIR)/%.cu.o : $(SRC_DIR)/%.cu $(CUH_FILES)
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -dc -c -o $@ $<

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.cpp $(H_FILES)
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -c -o $@ $<

$(EXECUTABLE): $(OBJS)
	$(NVCC) $(NVCCFLAGS) $(OBJS) -o  $@

clean:
	@$(RM) $(OBJ_DIR)/*
	@$(RM) $(BIN_DIR)/*exe
	@$(RM) $(BIN_DIR)/*exp
